#
# Cookbook:: cpe_slack
# Resources:: cpe_slack
#
# Copyright:: (c) 2020-present, Uber Technologies, Inc.
# All rights reserved.
#
# Copyright:: (c) 2020-present, Gusto, Inc.
# All rights reserved.
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
#

provides :cpe_slack
resource_name :cpe_slack
unified_mode true
default_action :config

action_class do
  def set_signin_token(token)
    return if node.console_user.nil?

    path = value_for_platform_family(
      "windows" => "C:/Users/#{node.console_user}/AppData/Roaming/Slack",
      "mac_os_x" => "/Users/#{node.console_user}/Library/Application Support/Slack",
      "default" => nil,
    )

    return unless ::File.directory?(path)

    contents = { "default_signin_team" => token }.to_json

    file "#{path}/Signin.slacktoken" do
      content contents
      owner node.console_user
      ignore_failure true
    end
  end
end

# Enforce Slack Settings
action :config do
  signin_token = node["cpe_slack"]["signin_token"]

  unless signin_token.nil?
    set_signin_token(signin_token)
  end

  return unless macos?

  slack_prefs = node["cpe_slack"].reject { |k, v| v.nil? || k == "signin_token" }
  prefix = node["cpe_profiles"]["prefix"]
  organization = node["organization"] || "Uber"
  slack_profile = {
    "PayloadIdentifier" => "#{prefix}.slack",
    "PayloadRemovalDisallowed" => true,
    "PayloadScope" => "System",
    "PayloadType" => "Configuration",
    "PayloadUUID" => "063EE72F-E58C-46DB-AC68-A76F09676DE3",
    "PayloadOrganization" => organization,
    "PayloadVersion" => 1,
    "PayloadDisplayName" => "Slack",
    "PayloadContent" => [],
  }
  unless slack_prefs.empty?
    slack_profile["PayloadContent"].push(
      "PayloadType" => "com.tinyspeck.slackmacgap",
      "PayloadVersion" => 1,
      "PayloadIdentifier" => "#{prefix}.slack",
      "PayloadUUID" => "2B098882-100B-4FE6-B1C8-24F33BD30672",
      "PayloadEnabled" => true,
      "PayloadDisplayName" => "Slack",
    )
  end

  slack_prefs.each_key do |key|
    next if slack_prefs[key].nil?
    slack_profile["PayloadContent"][0][key] = slack_prefs[key]
  end

  node.default["cpe_profiles"]["#{prefix}.slack"] = slack_profile
end
