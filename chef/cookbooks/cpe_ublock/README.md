cpe_ublock Cookbook
========================
Manage uBlock Origin settings.


Attributes
----------
* node['cpe_ublock']
* node['cpe_ublock']['advancedSettings']
* node['cpe_ublock']['disableDashboard']
* node['cpe_ublock']['disabledPopupPanelParts']
* node['cpe_ublock']['toOverwrite']
* node['cpe_ublock']['toAdd']
* node['cpe_ublock']['userSettings']

Usage
-----
The profile will manage the settings for the browser extension uBlock Origin. Presently, it manages settings for the Chrome extension, via a macOS configuration profile or Windows registry key.

Firefox could be cobbled together by using Gusto's `cpe_firefox` cookbook:

```
node.default['cpe_firefox']['profile']['3rdparty']['Extensions']['uBlock0@raymondhill.net'] = {
  "adminSettings" => {
    "whitelist" => node.default['cpe_ublock']['toAdd']['trustedSiteDirectives'],
    "selectedFilterLists" => node.default['cpe_ublock']['toOverwrite']['filterLists'],
  }
}
```

Due to how the attributes are compiled, user customizations need to specify values directly for Firefox:

```
node.default['cpe_firefox']['profile']['3rdparty']['Extensions']['uBlock0@raymondhill.net']["adminSettings"]["selectedFilterLists"] = [
  "https://www.i-dont-care-about-cookies.eu/abp/",
]
```

Preferences under the `toOverwrite` key will overwrite a users local settings, this is most preferences. Preferences `toAdd` append to existing settings, currently the only supported preference is `trustedSiteDirectives`, which manages domains in the "Trusted sites" tab (renamed from `netwhitelist` in uBlock Origin 1.29.0).

Additional configuration information can be found on the [uBlock Origin wiki](https://github.com/uBlockOrigin/uBlock-issues/wiki/Deploying-uBlock-Origin:-configuration).

Lists can be added to `filterLists` using either the [short identifier](https://github.com/gorhill/uBlock/blob/master/assets/assets.json) (for built-in lists like `easyprivacy`) or the URL of the filters, like `https://easylist.to/easylist/easyprivacy.txt`. Make sure to include `user-filters` in this array, otherwise customized user filter rules will not apply.

```
node.default['cpe_ublock']['toOverwrite']['filterLists'] += [
  "https://www.i-dont-care-about-cookies.eu/abp/",
]
```

Adding a local on-disk filter list requires adding the ["Allow access to file URLs"](https://github.com/uBlockOrigin/uBlock-issues/discussions/1754) permission to the extension in Chrome, allowing you to specify `file://` filter lists. This can only be done manually due to a [outstanding Chrome bug](https://bugs.chromium.org/p/chromium/issues/detail?id=173640). Local filter lists are not supported in Firefox.

The profile's organization key defaults to `Gusto` unless `node['organization']` is
configured in your company's custom init recipe. The profile will also use
whichever prefix is set in node['cpe_profiles']['prefix'], which defaults to `com.facebook.chef`



Credit to Zack McCauley, whose blog post inspired and guided this cookbook: https://wardsparadox.github.io/2019/02/ublock-origin-admin-settings-deployment/
