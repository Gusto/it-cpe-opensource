cpe_firefox Cookbook
========================
Manages Firefox settings using [policy templates](https://github.com/mozilla/policy-templates/).


Attributes
----------
* node['cpe_firefox']

Usage
-----
For macOS, this creates a profile to manage the `org.mozilla.firefox` preference domain. On Windows, it creates a `policies.json` file in the Firefox installation directory.

The profile's organization key defaults to `Gusto` unless `node['organization']` is
configured in your company's custom init recipe. The profile will also use
whichever prefix is set in node['cpe_profiles']['prefix'], which defaults to `com.facebook.chef`

If you used a previous version of cpe_firefox to manage Firefox Autoconfig files, this cookbook also deletes those unsupported config files.

### Managing Extensions

Mozilla maintains more robust documentation on [managing extensions](https://github.com/mozilla/policy-templates/blob/master/README.md#extensions), but the general idea is similar to Google Chrome. To manage an extension, add a hash/dictionary with the extension ID as the top level key. You can retrieve the extension ID by installing the extension and visiting <about:support>. (Un)Installation types are defined in `installation_mode`, with the values `allowed`,`blocked`,`force_installed`, and `normal_installed` (removable). Provide the installer XPI, optionally version-pinned, in `install_url`:

```
ExtensionSettings' => {
  'jid1-BoFifL9Vbdl2zQ@jetpack' => {
    'installation_mode' => 'normal_installed',
    'install_url' => 'https://addons.mozilla.org/firefox/downloads/latest/decentraleyes/latest.xpi'
  }
}
```

Assign default extension behavior with a wildcard. For example, to restrict XPI installs to only official Mozilla repos:

```
"*": {
    "blocked_install_message": "Extension install blocked. Contact IT support for assistance.",
    "install_sources": ["about:addons","https://addons.mozilla.org/"],
    "installation_mode": "blocked",
    "allowed_types": ["dictionary", "extension", "locale", "theme"]
  },
```