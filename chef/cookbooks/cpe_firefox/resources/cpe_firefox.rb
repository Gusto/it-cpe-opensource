#
# Cookbook:: cpe_firefox
# Resources:: cpe_firefox
#
# Copyright:: (c) 2021-present, Gusto, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

resource_name :cpe_firefox
unified_mode true
provides :cpe_firefox
default_action :config

action_class do
  def windows_config_for_directory(directory, firefox_prefs)
    return unless ::Dir.exist?(directory)

    firefox_windows_directory = "#{directory}\\distribution"

    directory firefox_windows_directory do
      owner "SYSTEM"
      rights :read, "Everyone"
    end

    firefox_policies = { 'policies': firefox_prefs }

    file "#{firefox_windows_directory}\\policies.json" do
      content Chef::JSONCompat.to_json_pretty(firefox_policies)
      rights :read, "Everyone"
      action :create
    end
  end

  def windows_config(firefox_prefs)
    return unless windows?

    [
      'C:\\Program Files (x86)\\Mozilla Firefox',
      'C:\\Program Files\\Mozilla Firefox',
    ].each do |dir|
      windows_config_for_directory(dir, firefox_prefs)
    end
  end

  def macos_config(firefox_prefs)
    return unless macos?

    prefix = node["cpe_profiles"]["prefix"]
    organization = node["organization"] || "Gusto"
    firefox_profile = {
      "PayloadIdentifier" => "#{prefix}.browsers.firefox",
      "PayloadRemovalDisallowed" => true,
      "PayloadScope" => "System",
      "PayloadType" => "Configuration",
      "PayloadUUID" => "6772026B-1FB1-4BE3-B73B-B91A5A3ABF8C",
      "PayloadOrganization" => organization,
      "PayloadVersion" => 1,
      "PayloadDisplayName" => "Firefox",
      "PayloadContent" => [],
    }
    unless firefox_prefs.empty?
      firefox_profile["PayloadContent"].push(
        "PayloadType" => "org.mozilla.firefox",
        "PayloadVersion" => 1,
        "PayloadIdentifier" => "#{prefix}.browsers.firefox",
        "PayloadUUID" => "1EEB045B-886E-46BC-8AE2-7CE031AFD02C",
        "PayloadEnabled" => true,
        "PayloadDisplayName" => "Firefox",
      )
    end

    firefox_prefs.each_key do |key|
      next if firefox_prefs[key].nil?
      firefox_profile["PayloadContent"][0][key] = firefox_prefs[key]
    end

    node.default["cpe_profiles"]["#{prefix}.browsers.firefox"] = firefox_profile
  end
end

# Enforce firefox Settings
action :config do
  return unless node["cpe_firefox"]["configure"]
  firefox_prefs = node["cpe_firefox"]["profile"].compact
  return if firefox_prefs.empty? || firefox_prefs.nil?

  macos_config(firefox_prefs) if macos?
  windows_config(firefox_prefs) if windows?
end
