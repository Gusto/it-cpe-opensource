#
#
# Cookbook Name:: cpe_textexpander
# Recipe:: default
#
# Gusto CPE Chef Cookbooks
# Copyright 2019 ZenPayroll, Inc., dba Gusto
#
# This product includes software developed by
# ZenPayroll, Inc., dba Gusto (http://www.gusto.com/).
#

# Always gate your recipe to the appropriate OSes!
return unless node.macos?

cpe_textexpander 'Configure textExpander' do
  only_if { node['cpe_textexpander']['configure'] }
end
