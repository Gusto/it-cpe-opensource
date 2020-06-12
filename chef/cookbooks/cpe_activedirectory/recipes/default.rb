#
# Cookbook Name:: cpe_activedirectory
# Recipes:: default
#
#
#
# Gusto CPE Chef Cookbooks
# Copyright 2019 ZenPayroll, Inc., dba Gusto
#
# This product includes software developed by
# ZenPayroll, Inc., dba Gusto (https://www.gusto.com/).
#

return unless node.macos?

cpe_activedirectory 'Apply cpe_activedirectory'
