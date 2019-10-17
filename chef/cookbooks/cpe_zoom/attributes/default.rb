#
# Cookbook:: cpe_zoom
# Attribute:: default
#
# Gusto CPE Chef Cookbooks
# Copyright 2019 ZenPayroll, Inc., dba Gusto
#
# This product includes software developed by
# ZenPayroll, Inc., dba Gusto (http://www.gusto.com/).

default['cpe_zoom']['configure'] = false
default['cpe_zoom']['plist_path'] = '/Library/Preferences/us.zoom.config.plist'

default['cpe_zoom']['client_preferences'] = {
  'nogoogle' => '1',
  'nofacebook' => '1',
  'ZDisableVideo' => nil,
  'ZAutoJoinVoip' => true,
  'ZAutoUpdate' => false,
  'ZDualMonitorOn' => nil,
  'ZAutoSSOLogin' => true,
  'ZSSOHost' => nil,
  'ZAutoFullScreenWhenViewShare' => nil,
  'ZAutoFitWhenViewShare' => true,
  'ZUse720PByDefault' => nil,
  'ZRemoteControlAllApp' => true
}
