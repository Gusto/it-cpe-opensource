# SPDX-FileCopyrightText: Gusto, Inc.
#
# SPDX-License-Identifier: Apache-2.0

# Cookbook:: cpe_mdm_profiles
# Attributes:: default

default["cpe_mdm_profiles"]["middleware_config"] = {
  "device_id" => nil,
  "environment" => nil,
  "url_data_bag_name" => nil,
  "key_data_bag_name" => nil,
  "middleware_name" => nil,
}
