# Cookbook Name:: cpe_anyconnect
# Recipes:: default
#
# Gusto CPE Chef Cookbooks
# Copyright 2019 ZenPayroll, Inc., dba Gusto
#
# This product includes software developed by
# ZenPayroll, Inc., dba Gusto (http://www.gusto.com/).
#
# This source code is licensed under the Apache 2.0 license found in the
# LICENSE file in the root directory of this source tree.
#

cpe_anyconnect 'Manage Cisco AnyConnect' do
  action :manage
end

cpe_anyconnect 'Manage Cisco AnyConnect shortcut shim' do
  action :install_shortcut_shim
  only_if { macos? }
end
