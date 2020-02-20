# Cookbook Name:: cpe_notifications
# Resource:: cpe_notifications
#
#
#
# Gusto CPE Chef Cookbooks
# Copyright 2019 ZenPayroll, Inc., dba Gusto
#
# This product includes software developed by
# ZenPayroll, Inc., dba Gusto (http://www.gusto.com/).
#

require 'plist'

# You'll generally want a custom resource for each platform that provides
# functionality for each specific OS.
resource_name :cpe_notifications_darwin
# The value for "provides" is the actual name of the custom resource that is
# called from your recipes/default.rb file.
# Even though this file is named "cpe_notifications_darwin" (because it's macOS-only),
# it provides a custom resource that can be called with "cpe_notifications".
# The "os" is what OSes this resource is supported to run on.
# Chef will throw an error and halt if you call a custom resource on a platform
# that is not supported.
provides :cpe_notifications, :os => 'darwin'
# You can specify multiple actions for a custom resource, but typically
# you'll only ever need one. This default_action corresponds to the action
# section below.
default_action :run

action :run do
  return unless node['cpe_notifications']['configure']

  prefs = node['cpe_notifications']['applications'].reject { |_k, v| v.empty? }
  if prefs.empty?
    Chef::Log.info("#{cookbook_name}: No prefs found.")
    return
  end

  organization = node['organization'] ? node['organization'] : 'Gusto'
  prefix = node['cpe_profiles']['prefix']
  profile = {
    'PayloadIdentifier' => "#{prefix}.notifications",
    'PayloadRemovalDisallowed' => true,
    'PayloadScope' => 'System',
    'PayloadType' => 'Configuration',
    'PayloadUUID' => 'E8275447-FE4C-4D83-A868-7CFBC5F8DCF0',
    'PayloadVersion' => 1,
    'PayloadDisplayName' => 'Notifications',
    'PayloadOrganization' => organization,
    'PayloadContent' => [],
  }
  unless prefs.empty?
    prefs.each do |bundle, n_prefs|
      prefs_to_write = n_prefs.dup
      prefs_to_write['BundleIdentifier'] = bundle
      profile['PayloadContent'].push(
        {
          'NotificationSettings' => [prefs_to_write],
          'PayloadDescription' => "Manage notification settings for #{bundle}",
          'PayloadDisplayName' => 'Notifications',
          'PayloadEnabled' => true,
          'PayloadIdentifier' => '6758184B-ED25-4685-9235-0F0535D06E57',
          'PayloadOrganization' => organization,
          'PayloadType' => 'com.apple.notificationsettings',
          'PayloadUUID' => node.get_uuid,
        }
      )
    end
  end
  node.default['cpe_profiles']["#{prefix}.notifications"] = profile
end
