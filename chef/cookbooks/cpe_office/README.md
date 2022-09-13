Description
==================
Suppresses the First Run / Welcome screens, disables telemetry, and macros for Microsoft Office 2016, 2019, and 2021 LTSC on macOS and Windows.

Requirements
-----------
macOS
Windows
Microsoft Office, because no one's written cpe_libreoffice yet

Attributes
----------
* node['cpe_office']['configure']
* node['cpe_office']['mac']['mau']
* node['cpe_office']['mac']['o365']
* node['cpe_office']['mac']['onenote']
* node['cpe_office']['mac']['excel']
* node['cpe_office']['mac']['outlook']
* node['cpe_office']['mac']['powerpoint']
* node['cpe_office']['mac']['word']
* node['cpe_office']['mac']['global']
* node['cpe_office']['win']['global']
* node['cpe_office']['win']['word']
* node['cpe_office']['win']['excel']
* node['cpe_office']['win']['powerpoint']

Usage
-----

### macOS

On macOS, a profile will be applied to configure Word, PowerPoint, Excel, Outlook, and OneNote. The profile will suppress first run behavior and disable telemetry when possible.

The Microsoft AutoUpdate (MAU) aspects of this cookbook will manage the `com.microsoft.autoupdate2` preference domain. Further info can be found at: https://macadmins.software/docs/MAU_38.pdf

### Windows

Windows settings for Word, PowerPoint, and Excel are managed through registry keys. The general structure of a registry key is as such:

```
node.default['cpe_office']['win']['excel'] = {
  'Options' => { # Registry key path (truncated)
    'AlertIfNotDefault' => { # Registry key name
      'data' => 0, # Don't nag user # Registry key value
    },
  },
  ...
  'Security' => {
    'VBAwarnings' => {
      'data' => 4,  # Disable macros without warning
      'type': :dword, # Optional, defaults to :dword
    },
  }
}
```

The top level key, used for the registry key's path, is appended to the end of the application's base registry path. For example, the full registry path for Excel is `HKEY_CURRENT_USER\Software\Policies\\Microsoft\Office\\16.0\Excel\`. For improved readability/concision, you only need to include the end part of your key's path, in above example this would be `Security` or `Options`.

The default [registry key type](https://docs.chef.io/resources/registry_key/#syntax) is `:dword`, which can be overridden by defining a `type` in your preference hash.

Each newly defined key should be added this cookbook's default attributes as nil. This allows Chef to delete keys that are no longer managed by use. Any key with `data` set as `nil` will be deleted.
