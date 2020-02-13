# frozen_string_literal: true
#
#
# Cookbook Name:: cpe_zoom
# Resources:: default
#
# Gusto CPE Chef Cookbooks
# Copyright 2019 ZenPayroll, Inc., dba Gusto
#
# This product includes software developed by
# ZenPayroll, Inc., dba Gusto (http://www.gusto.com/).
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

resource_name :cpe_zoom
provides :cpe_zoom
default_action :config

action :config do
  return unless node['cpe_zoom']['configure']

  prefs = node['cpe_zoom']['client_preferences'].reject { |_k, v| v.nil? }

  file node['cpe_zoom']['plist_path'] do
    content prefs.to_plist
  end
end
