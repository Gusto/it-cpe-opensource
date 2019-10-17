#
# Cookbook Name:: cpe_hot_corners
# Recipes:: default
#
#
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

return unless node.macos?

cpe_hot_corners 'Apply Hot Corner enforcement'
