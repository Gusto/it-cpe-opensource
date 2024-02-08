# simplemdm_os_update

An AWS Lambda Function to schedule OS updates via MDM command by targeting a dictionary of SimpleMDM device groups. This is intended to be triggered by a cloudwatch scheduled event.

A list of device IDs is parsed from each group and then iterated over to send MDM update commands. By default, updates are forced without user interaction (macOS only - `force_update` / `InstallForceRestart`) and for the latest minor version. Refer to SimpleMDM's API documentation (https://api.simplemdm.com/#update-os) for other supported arguments, which generally map to Apple's MDM spec (https://developer.apple.com/documentation/devicemanagement/scheduleosupdatecommand/command/updatesitem):

`os_update_mode`: `download_only`, `notify_only`, `install_asap`, `force_update`
`version_type`: `latest_minor_version`, `latest_major_version`

To add or remove device groups, modify the `SIMPLEMDM_DEVICE_GROUPS` environemnt variable in your function. Note `os_update_mode` is only supported for macOS and ignored for iOS/tvOS. The key can still be included safely, which is useful for diverse groups of device types.

### Device group example
```
{
    "group_id"       = "1337", # service devices
    "os_update_mode" = "force_update",
    "version_type"   = "latest_minor_version",
},
{
    "group_id"       = "2600", # user devices
    "os_update_mode" = "force_update",
    "version_type"   = "latest_minor_version",
},
```

An update command is sent for every device in each device group, even if they aren't eligible since checking for eligibility and current OS version would mean yet another API call to SimpleMDM. Instead, SimpleMDM decides what action to take based on server side data. It's normal for the result output to include devices which either are already up to date ("An update for this device is not available") or no longer enrolled ("This device is not eligible for an OS update"). 

```
Queueing OS update commands for device groups foo, bar, Test Group1
Device IDs: [985162, 1062487, 635195, 991817]
 Error: {"errors":[{"title":"An update for this device is not available"}]}. Status code: 422. Device ID: 985162.
 Error: {"errors":[{"title":"This device is not eligible for an OS update."}]}. Status code: 422. Device ID: 1062487.
 Error: {"errors":[{"title":"This device is not eligible for an OS update."}]}. Status code: 422. Device ID: 635195.
 Error: {"errors":[{"title":"This device is not eligible for an OS update."}]}. Status code: 422. Device ID: 991817.
```

While this is currently only used for unattended devices, the implementation makes it possible to target other device groups in the future, including iOS/iPadOS devices.
