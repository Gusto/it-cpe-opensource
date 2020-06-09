cpe_ublock Cookbook
========================
Install a profile to manage diagnostic information submission settings.


Attributes
----------
* node['cpe_ublock']['adminSettings']
* node['cpe_ublock']['adminSettings']['userSettings']
* node['cpe_ublock']['adminSettings']['selectedFilterLists']
* node['cpe_ublock']['adminSettings']['netWhitelist']

Usage
-----
The profile will manage the settings for the browser extension uBlock Origin.

Presently, it only manages settings for the Chrome extension, via a macOS profile. Firefox support to come.

The profile's organization key defaults to `Gusto` unless `node['organization']` is
configured in your company's custom init recipe. The profile will also use
whichever prefix is set in node['cpe_profiles']['prefix'], which defaults to `com.facebook.chef`

The profile delivers a payload for the above keys in `node['cpe_ublock']`.  I encourage checking a default uBlock install to get an idea of defaults.

Credit to Zack McCauley, whose blog post inspired and guided this cookbook: https://wardsparadox.github.io/2019/02/ublock-origin-admin-settings-deployment/
