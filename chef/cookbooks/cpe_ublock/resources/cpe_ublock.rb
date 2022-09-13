#
# Cookbook:: cpe_ublock
# Resources:: cpe_ublock
#
# Copyright:: (c) 2020-present, Gusto, Inc.
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
require "json"

provides :cpe_ublock
resource_name :cpe_ublock
unified_mode true
default_action :run

# Enforce Ublock Settings

action_class do
  def windows_config(ublock_prefs)
    return unless windows?

    ublock_prefs.each do |reg_key, reg_value|
      # Configure Google Chrome. Microsoft Edge would be similar:
      # MICROSOFT_EDGE_REGISTRY_KEY = 'HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Edge\3rdparty\Extensions\odfafepnkmbhccpbejgmiehpchacaeak\policy'

      registry_key 'HKEY_LOCAL_MACHINE\Software\Policies\Google\Chrome\3rdparty\extensions\cjpalhdlnbpafiamejdnhcphjbkeiagm\policy' do
        values [{
          name: reg_key,
          type: :string,
          data:  Chef::JSONCompat.to_json(reg_value),
          }]
        recursive true
        action :create
      end
    end
  end

  def macos_config(ublock_prefs)
    return unless macos?
    prefix = node["cpe_profiles"]["prefix"]
    organization = node["organization"] || "Gusto"
    profile = {
      "PayloadIdentifier" => "#{prefix}.ublock",
      "PayloadRemovalDisallowed" => true,
      "PayloadScope" => "System",
      "PayloadType" => "Configuration",
      "PayloadUUID" => "B85D1054-286C-4122-8653-FA48B8751D54",
      "PayloadOrganization" => organization,
      "PayloadVersion" => 1,
      "PayloadDisplayName" => "uBlock Origin",
      "PayloadContent" => [],
    }

    unless ublock_prefs.empty?
      profile["PayloadContent"].push(
        "PayloadType" => "com.google.Chrome.extensions.cjpalhdlnbpafiamejdnhcphjbkeiagm",
        "PayloadVersion" => 1,
        "PayloadIdentifier" => "#{prefix}.ublock",
        "PayloadUUID" => "04217FF8-3430-4618-AE3C-867DD07B89BF",
        "PayloadEnabled" => true,
        "PayloadDisplayName" => "uBlock Origin",
      )
      ublock_prefs.each_key do |key|
        next if ublock_prefs[key].nil?
        profile["PayloadContent"][0][key] = ublock_prefs[key]
      end
    end

    node.default["cpe_profiles"]["#{prefix}.ublock"] = profile
  end
end

action :run do
  ublock_prefs = node["cpe_ublock"].compact

  return if ublock_prefs.empty? || ublock_prefs.nil?

  macos_config(ublock_prefs) if macos?
  windows_config(ublock_prefs) if windows?
end
