Attributes
=================
- default['cpe_hot_corners']['configure']
- default['cpe_hot_corners']['hot_corner_map']
- default['cpe_hot_corners']['settings']['compliant_values']
- default['cpe_hot_corners']['settings']['corner_keys']
- default['cpe_hot_corners']['settings']['dock_plist']
- default['cpe_hot_corners']['settings']['default_compliant_value']
- default['cpe_hot_corners']['notification_cadence']
- default['cpe_hot_corners']['enforce']


Requirements
=================
cpe_yo - alerting Cookbook
cpe_utils - Facebook/Gusto utility node functions


Usage
=================
Define the compliant corner action(s) with `default['cpe_hot_corner']['default_compliant_value']` and/or `default['node']['compliant_values']`.

You may choose to enforce a hot corner with `node['cpe_hot_corners']['enforce']`. If a free corner is detected, it will be set to the first compliant value. An alert will be spawned informing the user.

If enforce is not set (but `configure` still is), the user will be asked via alert to configure a corner. The operator may define a `notification_cadence` (in days), if `0`, an alert will be spawned on every run of chef-client. You may also write a configure title and message. You should have Yo installed and cpe_yo cookbook in use.


Todo
=================
- Test with Catalina (the Dock plist used is undocumented.)

Dependencies
=================

- cpe_yo, for bugging users
- cpe_utils
