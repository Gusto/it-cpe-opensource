#
# Cookbook:: cpe_yo
# Attributes:: default
#
# Gusto CPE Chef Cookbooks
# Copyright 2019 ZenPayroll, Inc., dba Gusto
#
# This product includes software developed by
# ZenPayroll, Inc., dba Gusto (http://www.gusto.com/).
#

default['cpe_yo']['yo_binary'] = '/Applications/Utilities/yo.app/Contents/MacOS/yo'
default['cpe_yo']['configure'] = true
default['cpe_yo']['launchd'] = {
  'start_interval' => 30
}
# We never configure the alert schedule - never send any alerts - to these users
# (ie, the cpe_yo resource returns if this.include? node.console_user)
default['cpe_yo']['user_alert_blacklist'] = [
  'root',
  '_mbsetupuser'
]
