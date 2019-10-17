#
# Cookbook Name:: cpe_hot_corners
# Attributes:: default
#
#
#
# Gusto CPE Chef Cookbooks
# Copyright 2019 ZenPayroll, Inc., dba Gusto
#
# This product includes software developed by
# ZenPayroll, Inc., dba Gusto (http://www.gusto.com/).
#
# This source code is licensed under the Apache 2.0 license found in the
# LICENSE file in the root directory of this source tree.
#

default['cpe_hot_corners']['configure'] = false
default['cpe_hot_corners']['enforce'] = false

default['cpe_hot_corners']['configure_title'] = 'Please enable a Hot Corner'
default['cpe_hot_corners']['configure_message'] = 'For locking your Macbook'

# Internal only wipe if OSS
default['cpe_hot_corners']['notify_slack'] = true

# Days
default['cpe_hot_corners']['notification_cadence'] = 5

default['cpe_hot_corners']['hot_corner_map'] = {
  'none' => 1,
  'mission_control' => 2,
  'application_windows' => 3,
  'desktop' => 4,
  'screen_saver' => 5,
  'disable_screen_saver' => 6,
  'dashboard' => 7,
  'sleep' => 10,
  'launchpad' => 11,
  'notification_center' => 12,
  'screen_lock' => 13
}
default['cpe_hot_corners']['settings']['compliant_values'] = ['5', '13']
default['cpe_hot_corners']['settings']['corner_ids'] =
  ['wvous-tr-corner', 'wvous-br-corner', 'wvous-tl-corner', 'wvous-bl-corner']
default['cpe_hot_corners']['settings']['dock_plist'] =
  "/Users/#{node.console_user}/Library/Preferences/com.apple.dock.plist"
default['cpe_hot_corners']['settings']['default_compliant_value'] = '13'
