#
# Cookbook Name:: cpe_ublock
# Resource:: cpe_ublock
#
#
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


require 'json'

resource_name :cpe_ublock
default_action :run

action :run do
  prefs = node['cpe_ublock']['adminSettings'].compact
  prefix = node['cpe_profiles']['prefix']
  organization = node['organization'] || 'Gusto'
  return if prefs.empty?

  unless prefs["netWhitelist"].nil?
    prefs["netWhitelist"] = prefs["netWhitelist"].join("\n")
  end

  prefs = {'adminSettings' => prefs.to_json}

  profile = {
    'PayloadIdentifier' => "#{prefix}.ublock",
    'PayloadRemovalDisallowed' => true,
    'PayloadScope' => 'System',
    'PayloadType' => 'Configuration',
    'PayloadUUID' => 'B85D1054-286C-4122-8653-FA48B8751D54',
    'PayloadOrganization' => organization,
    'PayloadVersion' => 1,
    'PayloadDisplayName' => 'uBlock Origin',
    'PayloadContent' => [],
  }

  unless prefs.empty?
    profile['PayloadContent'].push(
      'PayloadType' => 'com.google.Chrome.extensions.cjpalhdlnbpafiamejdnhcphjbkeiagm',
      'PayloadVersion' => 1,
      'PayloadIdentifier' => "#{prefix}.ublock",
      'PayloadUUID' => '04217FF8-3430-4618-AE3C-867DD07B89BF',
      'PayloadEnabled' => true,
      'PayloadDisplayName' => 'uBlock Origin',
    )
    prefs.each_key do |key|
      next if prefs[key].nil?
      profile['PayloadContent'][0][key] = prefs[key]
    end
  end

  node.default['cpe_profiles']["#{prefix}.ublock"] = profile
end
