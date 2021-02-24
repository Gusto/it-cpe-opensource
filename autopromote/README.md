#### About

autopromote.py is run on cron on a munki_repo server. It promotes packages between
catalogs in an order and on a schedule configured in autopromote.json.

The script works by storing a "last_promoted" datetime in the \_metadata array on all
pkginfo.plist files it promotes.

Autopromote should be run daily, and operates on a promotion schedule of days. Admins may configure a schedule of catalogs, each with a package lifetime and a force install period. Admins may also specify different promotion speeds - channels, specific patch days, and specific force install times.

#### Setup

0. `mkdir .venv && virtualenv .venv && source .venv/bin/active` (py 2.7)
1. `pip install -r requirements.txt`
2. `python autopromote.py` (or cron to this effect)

#### Config

__catalogs__: A schedule of catalogs. Each should define the number of days a pkginfos
should live in this catalog, and the next catalog. If `next` is null, the catalog is
assumed to be the final catalog, no matter the `days` defined.

__denylist__: A list of pkginfos (as defined in their `name` attribute) on which no
action will ever be taken.

__allowlist__: A list of pkginfos (as defined in their `name` attribute) on which action
is permitted. This array takes precedence, define a pkginfo here and all others are
de facto in the denylist.

__munki_repo__: full path to the root munki_repo.

__fields_to_copy__: when a pkginfo is promoted for the first time (no `last_promoted`
value is set), autopromote.py searchs for a previous semantic version of the pkginfo.
If found, any/all of the fields in this array are copied to the newly promoted pkginfo.

__force_install_days__: If set, all newly promoted pkginfos receive a fresh force_install_after_date matching a T+this value. This is the default, to configure for specific packages use the `catalogs` hash.

__patch_tuesday__: An integer, 0-6, which specified the weekday to force force install dates to. For instance, if the force install date is 7 days from now, which falls on a Friday (4), and patch_tuesday is set to Tuesday (1), the force install date will be shifted by 4 days, to 11 days from now, in order to fall on the next Tuesday. This allows admins to automatically create a weekly predictability in their patch cycle.

A patch_tuesday of `null` will preclude any shift of force install dates.

__force_install_time__: The hour and minute, T+force_install_days, at which force install will take
effect.

Format: `{"hour": int, "minute": int}`

__enforce_force_install_time__: Have you decided 4:30 is a bad force install time? Set this value to true and configure the `force_install_time` to regulate the hour and minute, and, if set, the day (`patch_tuesday`) your package force install datetimes use.

__force_install_denylist__: A list of pkginfos (as defined in their `name` attribute) on which no force_install_after_date will ever be set.

__channels__: Channels allow one to specify a faster or slower promotion schedule for specific packages. This is a dictionary of channel names and an int or float multiplier:

`{"channels": {"slow": 2.5}}` - this channel configuration would cause any packages in the "slow" channel to be promoted 2.5 times *slower*. This is achieved by multiplying the current promotion period by the channel's value. If your promotion period is ten days, setting the slow channel to 2.5 would increase the time between promotions to twenty-five days. For faster promotion schedules, specify a float modifier of less than 1. For example, a multiplier of `0.5` would result in a 2x faster promotion schedule.

You may add a package to a channel by adding a channel key to the pkginfo metadata dict. If no channel is specified, or if a non-float/int value is specified, the channel modifier is always 1. A package in the "slow" channel would have this in its pkginfo:

```xml
<key>_metadata</key>
	<dict>
	   <key>channel</key>
          <string>slow</string>
	</dict>
```

If you're using [AutoPkg](https://github.com/autopkg/autopkg) you can configure this in your recipe override, so all versions of a package enter the same channel. Place the channel info in the `Input` section of your recipe override:

```xml
<key>metadata_additions</key>
		<dict>
		   <key>channel</key>
	          <string>slow</string>
		</dict>
```
