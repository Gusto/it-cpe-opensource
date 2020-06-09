#
# Cookbook Name:: cpe_ublock
# Attributes:: default
#
# Gusto CPE Chef Cookbooks
# Copyright 2020 ZenPayroll, Inc., dba Gusto
#
# This product includes software developed by
# ZenPayroll, Inc., dba Gusto (https://www.gusto.com/).
#

# These attributes, if set to nil, _do not_ reflect the current value or value
# which will be applied. All nil values are discarded and existing value for
# that key will persist. It was likely applied by a DirectoryService.managed
# profile.

default['cpe_ublock'] = {
  "adminSettings" => {
    "userSettings" => nil,
    "selectedFilterLists" => nil,
    "netWhitelist" => nil
  }
}
