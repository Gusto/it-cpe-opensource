#
#
# Cookbook Name:: cpe_textexpander
# Attributes:: default
#
# Gusto CPE Chef Cookbooks
# Copyright 2019 ZenPayroll, Inc., dba Gusto
#
# This product includes software developed by
# ZenPayroll, Inc., dba Gusto (http://www.gusto.com/).
#

# Only declare your basic attributes here.
# By default, these values should usually be `nil` or `false`, such that
# your cookbook should be a complete no-op if ran as-is.

# If you don't intend for someone to be able to overwrite this value,
# do not make it an attribute. All attributes are expected to be modifiable by
# any sort of customization.

# All of your default values for your cookbook should be done in
# cpe_base_settings (which apply to all nodes), or cpe_client (which apply only
# to client devices, which are employee laptops).

require 'date'
require 'chef/mixin/deep_merge'

default['cpe_textexpander'] = {
  'configure' => false,
  'preserve_existing' => true,
  'preference_domain' => 'com.smileonmymac.textexpander',
  'managed_snippet_label' => 'Gusto',
  'snippets_settings' => {
    'writabe' => 0,
    'updateFrequency' => 0,
    'snippetPlists' => [],
    'expandAfterMode' => 0,
    'expanderExceptionsMode' => 4,
  },
  'global_settings' => {
    "Hide Dock Icon" => nil,
    "HockeySDKAutomaticallySendCrashReports" => 0,
    "HockeySDKCrashReportActivated" => 1,
    "NSToolbar Configuration com.smileonmymac.textexpander.maintoolbar" => {
      "TB Display Mode" => nil,
      "TB Icon Size Mode" => nil,
      "TB Is Shown" => nil,
      "TB Size Mode" => nil,
    },
    "SUEnableAutomaticChecks" => 1,
    "SUHasLaunchedBefore" => nil,
    "SUSendProfileInfo" => nil,
    "TextExpanderPrefs.prefspanel.recentpage" => nil,
    "welcomeVisible" => nil,
  }
}

# Example addition to snippets
# node.default['cpe_textexpander']['snippets_settings']['snippetPlists'] += [
#   {
#     'abbreviation' => 'Test: created by Chef',
#     'abbreviationMode' => 0,
#     'creationDate' => DateTime.now,
#     'label' => 'use this to rofl',
#     'modificationDate' => DateTime.now,
#     'plainText' => ':roflcopter:'
#   }
# ]
# welcomeVisible is "TRUE" or "FALSE"
