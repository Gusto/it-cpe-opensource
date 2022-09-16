cpe_onepassword Cookbook
========================
Manage 1Password 8 and later JSON config using the CPE attributes API pattern on macOS and Windows.

Depends on [Facebook's cpe_helper's cookbook](https://github.com/facebook/IT-CPE/tree/main/itchef/cookbooks/cpe_helpers/libraries).

Attributes
-----
* default["cpe_onepassword"]["configure"] # Unless true, always no-ops
* default["cpe_onepassword"]["create_if_missing"] # Create a settings.json if missing and write managed settings.
* default["cpe_onepassword"]["recursively_create_if_missing"] # Create all 1Password settings.json parent directories recursively. In addition, write settings.json with all managed settings.
* default["cpe_onepassword"]["manage_all_settings"] # If true, settings.json will be updated to contain _only_ those settings defined in Chef, deleting any unknown keys. Overwrites user and app created settings.
* default["cpe_onepassword"]["settings"] # Hash of JSON-serializable key/value pairs which are valid 1Password settings.

Settings
----
These can be set in the `["cpe_onepassword"]["settings"]` hash. Written to settings.json in `~/Library/Group Containers/2BUA8C4S2C.com.1password/Library/Application Support/1Password/Data/settings/settings.json`. To remove a setting (use 1Password's default), set the value to `nil`. These settings are undocumented and were discovered empirically by observing configuration changes. Test and use at your own risk.

* advanced.EnableDebuggingTools - Bool.
* app.formatSecureNotesUsingMarkdown - Bool.
* app.keepInTray - Bool. Keep 1Password in the menu bar.
* app.locale - String. Uses standard country code format or "default" for system language.
* app.startAtLogin - Bool.
* app.theme - String. "system", "light", "dark".
* app.trayAction - String. "menu", "quickAccess", "mainWindow".
* app.useHardwareAcceleration - Bool.
* app.zoomLevel - Int.
* appearance.interfaceDensity - String. "comfortable, "compact".
* browsers.extension.enabled - Bool. Allow extension unlock through app.
* developers.cliSharedLockState.enabled - Bool. Biometric unlock for 1Password CLI.
* itemDetails.showWebFormDetails - Bool. Show auto-saved web details.
* privacy.checkCompromisedWebsites - Bool.
* privacy.checkHibp - Bool. Check for vulnerable passwords.
* privacy.checkMfa - Bool. Check for sites supporting two factor authentication.
* privacy.downloadRichIcons - Bool. Show app and website icons.
* security.authenticatedUnlock.appleTouchId - Bool. True to allow TouchID.
* security.authenticatedUnlock.enabled - Bool. Both must be set to enable.
* security.autolock.minutes - Int.
* security.autolock.onDeviceLock - Bool. Lock on sleep, screensaver, or switching users.
* security.clipboard.clearAfter - Bool. Remove copied information and authentication codes after 90 seconds.
* security.deviceClipboardSharing - Bool. Use Universal Clipboard.
* security.holdToggleReveal - Bool. Hold option to toggle revealed fields.
* security.revealPasswords - Bool. Always show passwords and full credit card numbers.
* sidebar.showCategories - Bool.
* sidebar.showTags - Bool.
* sshAgent.enabled - Bool.
* sshAgent.storeKeyTitles - Bool.
* ui.ItemDetailWindowsOnTop - Bool.
* updates.autoUpdate - Bool.
* updates.updateChannel - String. "PRODUCTION", "BETA", "NIGHTLY".