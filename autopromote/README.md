#### About

`autopromote.py` is run via `cron` on a `munki_repo` server. It promotes packages between
catalogs in an order and on a schedule configured in `autopromote.json`.

The script works by storing a `last_promoted` datetime in the `_metadata` array on all
`pkginfo.plist` files it promotes.

#### Setup

0. `mkdir .venv && virtualenv .venv -p $(which python3) && source ./.venv/bin/activate` (py 3)
1. `pip install -r requirements.txt`
2. `python autopromote.py` (or `cron` to this effect)

#### Config

__catalogs__: A schedule of catalogs. Each should define the number of days a pkginfos
should live in this catalog, and the next catalog. If `next` is null, the catalog is
assumed to be the final catalog, no matter the `days` defined.

__blacklist__: A list of pkginfos (as defined in their `name` attribute) on which no
action will ever be taken.

__whitelist__: A list of pkginfos (as defined in their `name` attribute) on which action
is permitted. This array takes precedence, define a pkginfo here and all others are
de facto in the blacklist.

__munki_repo__: full path to the root munki_repo.

__fields_to_copy__: when a pkginfo is promoted for the first time (no `last_promoted`
value is set), autopromote.py searchs for a previous semantic version of the pkginfo.
If found, any/all of the fields in this array are copied to the newly promoted pkginfo.

__force_install_days__: If set, all newly promoted pkginfos receive a fresh force_install_after_date matching a T+this value.

__force_install_time__: The time, T+force_install_days, at which force install will take
effect.

__enforce_force_install_time__: Have you decided 4:30 is a bad force install time? Set this value and all pkginfos, once parsed, will have their force_install_after_date changed to reflect the it.

__force_install_blacklist__: A list of pkginfos (as defined in their `name` attribute) on which no force_install_after_date will ever be set.

__notify_slack__: Send a detailed slack notification after a promotion run. Note: this requires a `SLACK_TOKEN` defined in __envfile__ and an existing __slack_channel__ defined.

__logging_level__: Must be a level accepted by Python's logging lib.

__envfile__: A file containing secrets used for this script. At the moment, only `SLACK_TOKEN` lives here.

#### Todo

- Allow for promotion time to be configurable per package category
