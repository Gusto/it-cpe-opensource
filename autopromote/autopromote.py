#!/usr/bin/env python3
# Author: Harry Seeber, Gusto ITCPE
# Copyright 2019 ZenPayroll, Inc., dba Gusto
#

import os
import re
import sys
import json
import arrow
import logging
import datetime
import plistlib
import subprocess
from slacker import Slacker
from dotenv import load_dotenv
from xml.parsers.expat import ExpatError
from packaging import version as semantic_version
from logging.handlers import RotatingFileHandler
from logging import StreamHandler
from collections import OrderedDict

CONFIG_FILE = os.getenv("CONFIG_FILE", "/usr/local/munki/autopromote.json")
PKGINFOS_PATHS = []
DEBUG = bool(os.environ.get("DEBUG"))

# Because things get easier if the catalogs are ordered - we don't always need to check "next"
# in the catalog definition while considering a package for promotion.
def order_catalogs(catalogs):
    """
    Takes a list of catalogs and returns a dict ordered according the
    configured catalog schedule.
    """

    od = OrderedDict()
    keys = []
    keys_to_process = catalogs.keys()

    while keys_to_process:
        still_to_process = []
        for catalog in keys_to_process:
            definition = catalogs[catalog]
            nxt = definition["next"]

            if nxt is None:
                keys.insert(-1, catalog)

            elif nxt in keys:
                i = keys.index(nxt) - 1
                i = 0 if i == -1 else i
                keys.insert(i, catalog)
            else:
                still_to_process.append(catalog)

        keys_to_process = still_to_process.copy()

    for key in keys:
        od[key] = catalogs[key].copy()

    return od, keys


def load_deny_and_allow_lists(config):
    def load(*lists):
        for config_item in lists:
            if isinstance(config_item, list):
                config_item = {k: None for k in config_item}

            for name, version in config_item.copy().items():
                version = re.compile(
                    ".*" if version in [None, "all"] else version,
                    re.IGNORECASE,
                )
                config_item[name] = version

            yield config_item

    config["denylist"], config["allowlist"] = tuple(
        l for l in load(config["denylist"], config["allowlist"])
    )
    return config


def load_config():
    """Reads autopromote.json from hardcoded path CONFIG_FILE"""

    with open(CONFIG_FILE) as f:
        config = json.load(f)

    config["catalogs"], config["catalog_order"] = order_catalogs(config["catalogs"])
    config = load_deny_and_allow_lists(config)
    return config


def load_logger(logfile):
    """Returns logger object pointing to stdout or a file, as configured"""

    logger = logging.getLogger("autopromote")
    level = logging.DEBUG if DEBUG else logging.INFO

    formatter = logging.Formatter(
        "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    )

    if logfile == "stdout":
        handler = StreamHandler(sys.stdout)
    else:
        handler = RotatingFileHandler(logfile, maxBytes=1000000, backupCount=10)

    handler.setFormatter(formatter)
    logger.addHandler(handler)
    logger.setLevel(level)
    return logger


CONFIG = load_config()
logger = load_logger(CONFIG.get("logfile", "stdout"))
load_dotenv(dotenv_path=CONFIG.get("envfile", ".autopromote.env"))


def get_pkgs(root):
    """Returns a list of pkginfo paths given a root directory."""

    pkgs = []
    for directory, subdirs, pkginfos in os.walk(root):
        for pkginfo in pkginfos:
            pkgs.append(os.path.join(directory, pkginfo))
    return pkgs


def pkg_version(plist):
    """Returns parsed semantic version from plist"""

    return semantic_version.parse(plist["version"])


def safe_read_pkg(pkginfo):
    """Returns the contents of a pkginfo plist, or, if a parsing error occurs, None"""

    logger.info(f"parsing {pkginfo}")
    try:
        with open(pkginfo, "rb") as f:
            plist = plistlib.load(f)
    except (ExpatError, plistlib.InvalidFileException) as e:
        # This is raised if a plist cannot be parsed (generally because its not a plist, but some clutter eg DS_Store)
        logger.warning(f"Failed to parse {pkginfo} because: {repr(e)}")
        plist = None
    except Exception as e:
        logger.error(f"Error parsing {pkginfo}")
        raise e
    return plist


def get_force_install_time(plist):
    """Returns a force install datetime shifted to match the configured force_install_time"""

    f = arrow.get(plist["force_install_after_date"])
    r = f.shift(
        hours=(int(CONFIG["force_install_time"]["hour"] or 0) - f.hour),
        minutes=(int(CONFIG["force_install_time"]["minute"] or 0) - f.minute),
    )

    patch_day = CONFIG.get("patch_tuesday")
    if isinstance(patch_day, int) and patch_day <= 6 and patch_day >= 0:
        r = r.shift(weekday=patch_day)

    return r.datetime


def get_previous_pkg(current):
    """Returns the previous version of package in PKGINFOS_PATHS"""

    last = None
    current_version = pkg_version(current)
    for plist, pkginfo in PKGINFOS_PATHS:
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
            f"Determined that previous version of {current['name']} {current['version']} is {last['name']} {last['version']}"
        )
    else:
        logger.warning(f"found no previous packages for {current['name']}")

    return last


def get_force_install_days(catalog):
    """Returns the number of days a package should live in a catalog, as configured"""

    days = CONFIG["catalogs"].get(catalog, {}).get("force_install_days")
    if not isinstance(days, int):
        days = CONFIG["force_install_days"]

    return days


def get_ideal_catalogs(catalogs):
    """
    Given a list of catalogs, returns the catalog which appears last
    in CONFIG['catalog_order'] and and the list of catalogs leading up to that catalog
    """

    custom_catalogs = [c for c in catalogs if not c in CONFIG["catalog_order"]]
    config_catalogs = [c for c in CONFIG["catalog_order"] if c in catalogs]
    latest_catalog = None if not config_catalogs else config_catalogs[-1]

    if latest_catalog:
        new_catalogs = []
        for c in CONFIG["catalog_order"]:
            new_catalogs.append(c)
            if c == latest_catalog:
                break

        new_catalogs = new_catalogs + custom_catalogs
    else:
        new_catalogs = catalogs

    return latest_catalog, new_catalogs


def get_next_catalog(latest_catalog):
    """Returns the next catalog configured in the promotion schedule"""

    for i, catalog in enumerate(CONFIG["catalog_order"]):
        if catalog == latest_catalog:
            try:
                return CONFIG["catalog_order"][i + 1]
            except IndexError:
                return None

    return None


def get_channel_multiplier(plist):
    """Retrieve the float multiplier for plist's channel. Returns multiplier or 1"""

    channel = plist.get("_metadata", {}).get("channel")
    if channel is None:
        return 1.0

    multiplier = CONFIG.get("channels", {}).get(channel)
    if not isinstance(multiplier, (int, float)) or multiplier == 0:
        return 1.0

    return float(multiplier)


def permitted(name, version):
    match = lambda lst: lst.get(name) and lst[name].match(version)
    allowed = match(CONFIG["allowlist"])
    denied = match(CONFIG["denylist"])

    if allowed and denied:
        raise f"{name} is in both allow and deny lists!"

    if not allowed and CONFIG["allowlist"].get(name):
        logger.warning(
            f"Skipping {name}-{version}: {name} is in allowlist but version {version} not matched"
        )
        return False
    elif denied:
        logger.warning(f"Skipping {name}-{version}: in denylist")
        return False

    return True


def promote_pkg(current_plist, path):
    """
    Given a pkginfo plist, parse its catalogs, apply a new catalog (promotion)
    and shift force_install_after_date if neccessary.

    Returns a boolean promoted and a dict results
    """

    name = current_plist["name"]
    version = current_plist["version"]
    catalogs = current_plist["catalogs"]
    fullname = f"{name} {version}"
    plist = current_plist.copy()

    promoted = False
    result = {"plist": plist, "from": None, "to": None, "fullname": fullname}

    logger.info(f"Considering package {fullname}")

    if not permitted(name, version):
        return promoted, result

    if (
        CONFIG["enforce_force_install_time"]
        and CONFIG.get("force_install_time")
        and plist.get("force_install_after_date")
    ):
        plist["force_install_after_date"] = get_force_install_time(plist)

    latest_catalog, ideal_catalogs = get_ideal_catalogs(catalogs)
    plist["catalogs"] = ideal_catalogs

    logger.debug(f"Package {fullname} has a catalog of {latest_catalog}")
    promotion_period = CONFIG["catalogs"].get(latest_catalog, {}).get("days")
    logger.debug(f"Promotion period for package {fullname} is {promotion_period}")

    if promotion_period is None:
        logger.debug(
            f"No defined promotion period for {latest_catalog} catalog, skipping"
        )
        return promoted, result

    last_promoted = plist.get("_metadata", {}).get("last_promoted")
    if last_promoted is None:
        logger.debug(f"Package {fullname} has no last_promoted value!")

        # Is newly imported package
        if latest_catalog == CONFIG["catalog_order"][0]:
            last_promoted = plist["_metadata"].get("creation_date")

            previous_pkg = get_previous_pkg(plist)

            if previous_pkg:
                for key in CONFIG["fields_to_copy"]:
                    # Only copy the previous field if the new plist does not contain a conflicting value
                    if previous_pkg.get(key) and not plist.get(key):
                        plist[key] = previous_pkg[key]
            else:
                logger.info(f"No previous package found for {fullname}!")

    last_promoted = arrow.get(last_promoted) if last_promoted else None

    if last_promoted is None:
        promotion_due = False
    else:
        channel_shifted = promotion_period * get_channel_multiplier(plist)
        logger.debug(
            f"Channel-shifted promotion period for {fullname} is {channel_shifted}"
        )
        promotion_due = (arrow.now() - last_promoted).days >= channel_shifted

    if not promotion_due:
        return promoted, result

    next_catalog = CONFIG["catalogs"][latest_catalog]["next"]
    if next_catalog is None:
        assert (
            promotion_period is None
        ), "Cannot define a next catalog without a promotion period."
        return promoted, result

    plist["catalogs"].append(next_catalog)
    promoted = True
    result["pkginfo"] = path
    result["from"] = latest_catalog
    result["to"] = next_catalog
    plist["_metadata"]["last_promoted"] = arrow.now().datetime
    if not name in CONFIG["force_install_denylist"]:
        plist["force_install_after_date"] = (
            arrow.now().shift(days=+get_force_install_days(next_catalog)).datetime
        )

        if CONFIG.get("enforce_force_install_time") and CONFIG.get("force_install_time"):
            plist["force_install_after_date"] = get_force_install_time(plist)

    logger.info(f"Promoted {fullname} from {result['from']} to {result['to']}")

    return promoted, result


def promote_pkgs(pkginfos):
    """
    Iterate over pkgs and pass them to promote_pkg if not in denylist.

    Returns a list of results from promote_pkg.
    """

    promotions = {}

    for plist, path in pkginfos:
        promoted, result = promote_pkg(plist, path)
        if promoted:
            promotions[result["fullname"]] = result

        with open(path, "wb") as f:
            plistlib.dump(result["plist"], f)

        logger.debug(f"wrote {result['fullname']} to {path}")

    return promotions


def notify_slack(promotions, error):
    """
    Given a list of resuilts from promote_pkgs, send a slack alert with a summary
    """

    token = os.environ.get("SLACK_TOKEN")
    if not token:
        logger.error("No SLACK_TOKEN is in environment, skipping slack output")
        return
    attachments = {
        "fields": [
            {"title": pkg, "value": f"{result['from']} => {result['to']}"}
            for pkg, result in promotions.items()
        ],
        "color": "danger" if error else "good",
        "title": "Autopromotion run completed",
        "text": ""
        if promotions
        else "No packages promoted"
        if not error
        else f"Error: {error}",
        "footer": "Alerts #withGusto",
    }
    logger.debug(promotions)
    logger.debug(attachments)
    Slacker(token).chat.post_message(
        CONFIG.get("slack_channel", "#test-please-ignore"),
        text="new autopromote.py run complete",
        username="munki autopromoter",
        icon_emoji=":munki:",
        attachments=[attachments],
    )


def output_results(promotions, error):
    """
    Given a list of results from promote_pkgs, write a file to disk
    """

    file_path = CONFIG.get("output_results_path", "results.plist")

    with open(file_path, "wb") as f:
        if error:
            plistlib.dump(error, f)
        else:
            plistlib.dump(promotions, f)


def main():
    logger.info("\n========================================\n")
    repo = os.path.join(CONFIG["munki_repo"], "pkgsinfo")
    logger.info("Autopromote: scanning munki_repo/pkgsinfo")
    promotions = {}
    error = None
    try:
        # Hello, this looks scary. It is not. We filter a list of packages
        # by whether safe_read_pkg returns None or a parsed plist.
        # This generates our list of valid packages to operate on.
        pkgs = filter(
            lambda x: x[0] != None, map(lambda x: [safe_read_pkg(x), x], get_pkgs(repo))
        )

        # We write that list to a global variable. Several functions iterate
        # over it, and this seems cleaner than passing the value around or going full OO.
        global PKGINFOS_PATHS
        PKGINFOS_PATHS = [p for p in pkgs]

        # Let's do the promoting!
        promotions = promote_pkgs(PKGINFOS_PATHS)

        if CONFIG.get("run_makecatalogs", True):
            logger.debug("Calling makecatalogs...")
            subprocess.call(
                ["/usr/local/munki/makecatalogs", CONFIG["munki_repo"]],
                stdout=open(os.devnull, "w"),
            )
    except Exception as e:
        logger.error(e)
        error = e
        raise e
    finally:
        if CONFIG.get("notify_slack"):
            notify_slack(promotions, error)
        if CONFIG.get("output_results"):
            output_results(promotions, error)
        logging.shutdown()


if __name__ == "__main__":
    main()
