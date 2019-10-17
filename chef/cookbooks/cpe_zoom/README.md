cpe_zoom
==================

Manages the config plist file for Zoom Meetings client.

Attributes
----------
* node.default['cpe_zoom']['plist_path']

    - Path to `us.zoom.config.plist` (string)


* node.default['cpe_zoom']['client_preferences']['configure']

    - On/off switch for this cookbook (override in init recipe)


* node.default['cpe_zoom']['client_preferences']['nogoogle']

    - Disables Google SSO (integer string value)


* node.default['cpe_zoom']['client_preferences']['nofacebook']

    - Disables Facebook SSO (integer string value)


* node.default['cpe_zoom']['client_preferences']['ZDisableVideo']

    - Disable camera upon joining meeting (boolean)


* node.default['cpe_zoom']['client_preferences']['ZAutoJoinVoip']

    - Enable join audio upon joining meeting (boolean)


* node.default['cpe_zoom']['client_preferences']['ZDualMonitorOn']

    - Automatically enable dual monitor support (boolean)


* node.default['cpe_zoom']['client_preferences']['ZAutoSSOLogin']

    - Default client to login to Zoom client with, below specified, SSO URL (boolean)


* node.default['cpe_zoom']['client_preferences']['ZSSOHost']

    - Defines SSO URL (corp.zoom.us) (string)


* node.default['cpe_zoom']['client_preferences']['ZAutoFullScreenWhenViewShare']

    - Enables automatically enter full screen when viewing shared content (boolean)


* node.default['cpe_zoom']['client_preferences']['ZAutoFitWhenViewShare']

    - Enables automatically fit to window when viewing shared content (boolean)


* node.default['cpe_zoom']['client_preferences']['ZUse720PByDefault']

    - Enables HD Video by default (boolean)


* node.default['cpe_zoom']['client_preferences']['ZRemoteControlAllApp']

    - Remote control all applications (boolean)

* node.default['cpe_zoom']['client_preferences']['ZAutoUpdate']

    - Enable built-in autoupdates (boolean)
