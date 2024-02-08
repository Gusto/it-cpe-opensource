# SPDX-FileCopyrightText: Gusto, Inc.
#
# SPDX-License-Identifier: Apache-2.0

# Cookbook:: cpe_mdm_profiles
# Recipe:: default

return unless macos?

# We can get away with inspecting cpe_mdm_profiles node attributes since it is the last recipe to run
enabled_profiles = node.default["cpe_mdm_profiles"].select { |_, v| v["enabled"] == true && v.key?("payloads") }
enabled_profiles.each do |identifier, payloads|
  payloads_hash = {}

  payloads["payloads"].each do |payload|
    payload_type = payload["PayloadType"]

    if payloads_hash.key?(payload_type)
      payloads_hash[payload_type].push(payload.compact)
    else
      payloads_hash[payload_type] = [payload.compact]
    end

    payloads_hash.each_value do |v|
      v.map { |k| k.delete("PayloadType") }
    end
  end

  macos_mdm_profile identifier do
    payload payloads_hash
    label identifier
    action :install
  end
end

zap_macos_mdm_profile "Cleanup outdated profiles" do
  label "foocorp.*"
end
