# Copyright:: (c) Gusto, Inc. and its affiliates.
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

# Cookbook:: cpe_onepassword
# Resources:: cpe_onepassword

provides :cpe_onepassword, os: ["darwin", "windows"]
resource_name :cpe_onepassword
unified_mode true
default_action :config

action_class do
  def config_file_empty?
    ::File.empty?(file_path)
  end

  def config_file_exist?
    ::File.exist?(file_path)
  end

  def current_settings
    @current ||= if config_file_exist? && !config_file_empty?
      JSON.parse(::File.read(file_path))
    end
  end

  def config_dir_exist?
    ::Dir.exist?(settings_dir)
  end

  def settings_dir
    @settings_dir ||= begin
      base_dir = value_for_platform_family(
        "mac_os_x" => "Library/Group Containers/2BUA8C4S2C.com.1password/Library/Application Support/1Password/Data/settings",
        "windows" => "AppData/Local/1Password/settings",
      )
      ::Pathname.new(node.console_user_home_dir).join(base_dir)
    end
  end

  def file_path
    @file_path ||= ::File.join(settings_dir, "settings.json")
  end

  def managed_settings
    @managed_settings ||= node["cpe_onepassword"]["settings"].compact
  end

  def settings
    @settings ||= if current_settings
      enforced = current_settings.compact
      unless enforced.nil?
        enforced = current_settings.merge(managed_settings).compact
      end
    end

    if node["cpe_onepassword"]["manage_all_settings"] || current_settings.nil?
      enforced = managed_settings
    end

    enforced
  end
end

action :config do
  return unless node["cpe_onepassword"]["configure"]

  {
    ::File.expand_path("../../../../..", settings_dir) => "700",
    ::File.expand_path("../../../..", settings_dir) => "700",
    ::File.expand_path("../../..", settings_dir) => "700",
    ::File.expand_path("../..", settings_dir) => "755",
    ::File.expand_path("..", settings_dir) => "755",
    settings_dir => "700",
  }.each do |dir, octal|
    directory dir do
      owner node.console_user
      group macos? ? "staff" : nil
      mode macos? ? octal : nil
      not_if { config_dir_exist? }
      only_if { node["cpe_onepassword"]["recursively_create_if_missing"] }
      action :create
    end
  end

  file file_path do
    content Chef::JSONCompat.to_json_pretty(settings)
    owner node.console_user
    group macos? ? "staff" : nil
    mode macos? ? "600" : nil
    only_if { config_dir_exist? }
    only_if { config_file_exist? || node["cpe_onepassword"]["recursively_create_if_missing"] || node["cpe_onepassword"]["create_if_missing"] }
    action :create
  end
end
