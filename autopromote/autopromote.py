#
# Gusto CPE Munki Autopromote
# Copyright 2019 ZenPayroll, Inc., dba Gusto
#

# This script is run on cron on a munki_repo server. It promotes packages between
# catalogs in an order and on a schedule defined in CONFIG_FILE (json).
# In the it-cpe repo, you may find an example config in the same directory as this script.

import os
import sys
import json
import arrow
import logging
import datetime
import subprocess
import plistlib as Plist
from slacker import Slacker
from dotenv import load_dotenv
from xml.parsers.expat import ExpatError
from packaging import version as semantic_version
from logging.handlers import RotatingFileHandler


CONFIG_FILE = "/usr/local/munki/autopromote.json"
LOG_FILE = "/var/log/autopromote.log"


def load_config():
    with open(CONFIG_FILE) as f:
        config = json.load(f)
    return config


def load_logger():
    logger = logging.getLogger("autopromote")
    logger.setLevel(logging.DEBUG)
    formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    handler = RotatingFileHandler(LOG_FILE, maxBytes=1000000, backupCount=10)
    handler.setFormatter(formatter)
    logger.addHandler(handler)
    return logger


CONFIG = load_config()
logger = load_logger()
load_dotenv(dotenv_path=CONFIG.get('envfile', '.autopromote.env'))


def get_pkgs(root):
    pkgs = []
    for directory, subdirs, pkginfos in os.walk(root):
        for pkginfo in pkginfos:
            pkgs.append(os.path.join(directory, pkginfo))
    return pkgs


def clean_plist_catalogs(plist_catalogs):
    config_catalogs = CONFIG["catalogs"].keys()
    custom_catalogs = [c for c in plist_catalogs if c not in config_catalogs]
    latest = None
    for c in set(plist_catalogs) & set(config_catalogs):
        next_catalog = CONFIG["catalogs"][c]["next"]
        latest = (
            next_catalog if next_catalog in plist_catalogs else latest if latest else c
        )
    return latest, custom_catalogs


def pkg_version(plist):
    return semantic_version.parse(plist["version"])


def safe_read_pkg(pkginfo):
    logger.info("parsing {}".format(pkginfo))
    try:
        plist = Plist.readPlist(pkginfo)
    except (ExpatError, Plist.InvalidFileException) as e:
        # This is raised if a plist cannot be parsed (generally because its not a plist, but some clutter eg DS_Store)
        logger.warn("Failed to parse {} because: {}".format(pkginfo, repr(e)))
        plist = None
    except Exception as e:
        logger.error("Error parsing {}".format(pkginfo))
        raise e
    return plist


def enforce_force_install_time(plist):
    if plist.get("force_install_after_date"):
        f = arrow.get(plist["force_install_after_date"])
        t = datetime.time(
            *[int(t.strip()) for t in CONFIG["force_install_time"].split(":")]
        )
        if t != f.time:
            f = f.replace(hour=t.hour, minute=t.minute)
            f = f.replace(tzinfo=datetime.timezone(datetime.timedelta(hours=-8)))
        plist["force_install_after_date"] = f.datetime
    return plist


def get_previous_pkg(pkginfos, current):
    last = None
    current_version = pkg_version(current)
    for plist, pkginfo in pkginfos:
        if plist["name"] == current["name"] and plist["version"] != current["version"]:
            plist_version = pkg_version(plist)
            if last:
                last_version = pkg_version(last)
                last = (
                    last
                    if plist_version < last_version
                    else plist
                    if plist_version < current_version
                    else last
                )
            else:
                last = plist
    if last:
        logger.debug(
            "Determined that previous version of {0} {1} is {2} {3}".format(
                current["name"], current["version"], last["name"], last["version"]
            )
        )
    else:
        logger.warn("found no previous packages for {0}".format(current["name"]))
    return last


def promote_pkgs(pkginfos):
    blacklist = CONFIG["blacklist"]
    whitelist = CONFIG["whitelist"]
    promotions = {}

    for plist, pkginfo in pkginfos:
        name = plist["name"]
        logger.debug("Considering package {} {}".format(name, plist["version"]))
        if name in blacklist or (whitelist and name not in whitelist):
            logger.warn("Skipping {}: excluded by whitelist/blacklist".format(name))
            continue

        if CONFIG["enforce_force_install_time"] and CONFIG.get("force_install_time"):
            plist = enforce_force_install_time(plist)

        catalog, custom_catalogs = clean_plist_catalogs(plist.get("catalogs"))
        logger.debug(
            "Package {} {} has a catalog of {}".format(name, plist["version"], catalog)
        )
        promotion_period = CONFIG["catalogs"].get(catalog, {}).get("days")

        # Promotion period is None if the catalog is production or the catalog is not listed in config
        if promotion_period:
            # Last promoted is none on the first run
            last_promoted = plist["_metadata"].get("last_promoted")
            last_promoted = arrow.get(last_promoted) if last_promoted else None
            if last_promoted:
                logger.debug(
                    "Package {} {} was last promoted {}".format(
                        name, plist["version"], last_promoted
                    )
                )
                # The Happy Path. FIXME: Refactor to follow Golden Path rule
                # ie, happy path should be aligned furthest left
                if (arrow.now() - last_promoted).days >= promotion_period:
                    next_catalog = CONFIG["catalogs"].get(catalog, {}).get("next")
                    assert (
                        next_catalog
                    ), "No next_catalog defined (but promotion days are defined) for {}".format(
                        catalog
                    )
                    plist["catalogs"] = custom_catalogs + [next_catalog]
                    plist["_metadata"]["last_promoted"] = arrow.now().format()
                    if not name in CONFIG["force_install_blacklist"]:
                        plist["force_install_after_date"] = (
                            arrow.now()
                            .shift(days=+CONFIG["force_install_days"])
                            .datetime
                        )
                    # Debug printing
                    logger.info(
                        "Promoted {0} {1} to {2}".format(
                            name, plist["version"], next_catalog
                        )
                    )
                    promotions["{0} {1}".format(name, plist["version"])] = (
                        catalog,
                        next_catalog,
                    )
            else:
                logger.debug(
                    "Package {0} {1} has no last_promoted value!".format(
                        name, plist["version"]
                    )
                )
                # If there's no last_promoted value, the package is probably new. So we write a last_promoted value of today.
                plist["_metadata"]["last_promoted"] = arrow.now().format()
                logger.info(
                    "Set new last_promoted date for {0} {1}".format(
                        name, plist["version"]
                    )
                )

                previous_pkg = get_previous_pkg(pkginfos, plist)
                if previous_pkg:
                    for key in CONFIG["fields_to_copy"]:
                        # Only copy the previous field if the new plist does not contain a conflicting value
                        if previous_pkg.get(key) and not plist.get(key):
                            plist[key] = previous_pkg[key]
                else:
                    logger.info(
                        "No previous package found for {0} {1}!".format(
                            name, plist["version"]
                        )
                    )
        Plist.writePlist(plist, pkginfo)

    return promotions


def notify_slack(promotions, error):
    token = os.environ.get('SLACK_TOKEN')
    if not token:
        logger.error('No SLACK_TOKEN is in environment, skipping slack output')
        return

    channel = CONFIG.get('slack_channel')
    if not channel:
        logger.error('No slack_channel is in config, skipping slack output')
        return

    attachments = {
        "fields": [
            {"title": k, "value": "{0} => {1}".format(*v)}
            for k, v in promotions.items()
        ],
        "color": "danger" if error else "good",
        "title": "Autopromotion run completed",
        "text": ""
        if promotions
        else "No packages promoted"
        if not error
        else "Error: {}".format(error),
        "footer": "Alerts #withGusto",
    }
    logger.debug(promotions)
    logger.debug(attachments)
    Slacker(token).chat.post_message(
        channel,
        text="new autopromote.py run complete",
        username="munki autopromoter",
        icon_emoji=":munki:",
        attachments=[attachments],
    )


def main():
    logger.info("\n========================================\n")
    logger.info("Autopromote: scanning munki_repo/pkginfo")
    promotions = {}
    error = None
    try:
        pkgs = filter(
            lambda x: x[0] != None,
            map(
                lambda x: [safe_read_pkg(x), x],
                get_pkgs(os.path.join(CONFIG["munki_repo"], "pkgsinfo")),
            ),
        )
        promotions = promote_pkgs([p for p in pkgs])
        logger.debug("Calling makecatalogs...")
        subprocess.call(["/usr/local/munki/makecatalogs", CONFIG["munki_repo"]], stdout=open(os.devnull, 'w'))
    except Exception as e:
        logger.error(e)
        error = e
        raise e
    finally:
        if CONFIG["notify_slack"]:
            notify_slack(promotions, error)
        logging.shutdown()


if __name__ == "__main__":
    main()
