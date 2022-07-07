#### About

autopromote.py is run on cron on a munki_repo server. It promotes packages between
catalogs in an order and on a schedule configured in autopromote.json.

The script works by storing a "last_promoted" datetime in the \_metadata array on all
pkginfo.plist files it promotes.

Autopromote should be run daily, and operates on a promotion schedule of days. Admins may configure a schedule of catalogs, each with a package lifetime and a force install period. Admins may also specify different promotion speeds - channels, specific patch days, and specific force install times.

### Setup

0. `mkdir .venv && virtualenv .venv && source .venv/bin/activate` (py 2.7)
1. `pip install -r requirements.txt`
2. `python3 autopromote.py` (or cron to this effect)

### Config

#### catalogs
A schedule of catalogs. Each should define the number of days a pkginfos
should live in this catalog, and the next catalog. If `next` is null, the catalog is
assumed to be the final catalog, no matter the `days` defined.

#### denylist
A dictionary of package_name: package_version_regex to refuse to promote. If the version is
`null`, promotions for all versions are blocked.

To block promoting all versions of BlueJeans and just 5.x versions
of Zoom, set:

```json
"denylist": {
	"Zoom": "5.*",
	"BlueJeans": null
}
```

#### allowlist
A dictionary of package_name: package_version_regex to refuse to promote. If a
package_name is set but, promotions which do not match package_version_regex will be blocked.

To allow only 8.x versions of Teleport, set:
```json
"allowlist": {
	"Teleport": "8.*"
}
```

#### munki_repo
 full path to the root munki_repo.

#### fields_to_copy
 when a pkginfo is promoted for the first time (no `last_promoted`
value is set), autopromote.py searchs for a previous semantic version of the pkginfo.
If found, any/all of the fields in this array are copied to the newly promoted pkginfo.

#### force_install_days
 If set, all newly promoted pkginfos receive a fresh force_install_after_date matching a T+this value. This is the default, to configure for specific packages use the `catalogs` hash.

#### patch_tuesday
An integer, 0-6, which specified the weekday to force force install dates to. For instance, if the force install date is 7 days from now, which falls on a Friday (4), and patch_tuesday is set to Tuesday (1), the force install date will be shifted by 4 days, to 11 days from now, in order to fall on the next Tuesday. This allows admins to automatically create a weekly predictability in their patch cycle.

Uses [Python's weekday implementation](https://docs.python.org/3/library/datetime.html#datetime.date.weekday) for days of the week.

| Integer Value | Day of the week |
|     :---:     | ---             |
|       0       | Monday          |
|       1       | Tuesday         |
|       2       | Wednesday       |
|       3       | Thursday        |
|       4       | Friday          |
|       5       | Saturday        |
|       6       | Sunday          |

A patch_tuesday of `null` will preclude any shift of force install dates.

#### force_install_time
 The hour and minute, T+force_install_days, at which force install will take
effect.

Format: `{"hour": int, "minute": int}`

#### enforce_force_install_time
 Have you decided 4:30 is a bad force install time? Set this value to true and configure the `force_install_time` to regulate the hour and minute, and, if set, the day (`patch_tuesday`) your package force install datetimes use.

#### force_install_denylist
 A list of pkginfos (as defined in their `name` attribute) on which no force_install_after_date will ever be set.

#### channels
 Channels allow one to specify a faster or slower promotion schedule for specific packages. This is a dictionary of channel names and an int or float multiplier:

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
