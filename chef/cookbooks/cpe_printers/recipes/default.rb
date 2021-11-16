#
#
# Cookbook Name:: cpe_printers
# Recipe:: default
#
# Gusto CPE Chef Cookbooks
# Copyright 2019 ZenPayroll, Inc., dba Gusto
#
# This product includes software developed by
# ZenPayroll, Inc., dba Gusto (http://www.gusto.com/).
#

return unless macos?

# Install printers
cpe_printers "Configure #{node['organization']} printers" do
  action :configure
end

# Clean printers not found in current printer list but with managed prefix
cpe_printers "Clean up #{node['organization']} printers" do
  action :clean_up
end
