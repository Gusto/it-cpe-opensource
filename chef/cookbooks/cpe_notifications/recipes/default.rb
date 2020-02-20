# Cookbook Name:: cpe_notifications
# Recipe:: default
#
#
#
# Gusto CPE Chef Cookbooks
# Copyright 2019 ZenPayroll, Inc., dba Gusto
#
# This product includes software developed by
# ZenPayroll, Inc., dba Gusto (http://www.gusto.com/).
#

return unless node.macos?

# Call the custom resource to handle all of your work
cpe_notifications 'Apple notification settings' do
  only_if { node['cpe_notifications']['configure'] }
  only_if { node['platform_version'].start_with?('10.15') }
end
