#
# Cookbook:: cpe_zoom
# Recipe:: default
#
# Gusto CPE Chef Cookbooks
# Copyright 2019 ZenPayroll, Inc., dba Gusto
#
# This product includes software developed by
# ZenPayroll, Inc., dba Gusto (http://www.gusto.com/).

return unless node.macos?

cpe_zoom 'Configure zoom.us'
