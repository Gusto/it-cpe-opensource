# SPDX-FileCopyrightText: Gusto, Inc.
#
# SPDX-License-Identifier: Apache-2.0

# Cookbook:: cpe_customizations
# Recipe:: node/C02ROFLHAH

require "base64"

# Wipe and re-install macOS on a non-MDM enrolled device.

service_account = "bart"
service_password = "elbarto"

macos_pkg "Erase install" do
  source "https://github.com/grahampugh/erase-install/releases/download/v32.0/erase-install-32.0.pkg"
  package_id "com.github.grahampugh.erase-install"
  checksum "30c15e623c91fee411a1c44e7c4b1e5326aa027b1120daaad55f61008ae44e1a"
end

user service_account do
  password service_password
  gid "admin"
end

# Generate base64 encoded string to pass through as account credentials
credentials = Base64.encode64("#{service_account}:#{service_password}").strip()

execute "Erase device" do
  command "/Library/Management/erase-install/erase-install.sh --erase --silent --credentials=#{credentials} --very-insecure-mode"
  action :run
end
