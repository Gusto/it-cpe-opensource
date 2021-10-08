# Copyright (c) Gusto, Inc. and its affiliates.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Cookbook Name:: cpe_profiles_workspaceone
# Resource:: cpe_profiles_workspaceone

resource_name :cpe_profiles_workspaceone
provides :cpe_profiles_workspaceone, :os => "darwin"
default_action :run

action_class do
  CONFIG_KEYS = [
    "__cleanup", "prefix", "lambda_config", "remote_profiles", "forced_profiles"
  ].freeze

  def prefix
    node["cpe_profiles_workspaceone"]["prefix"]
  end

  def use_hubcli?
    @use_hubcli ||= node["cpe_profiles_workspaceone"]["lambda_config"]["use_hubcli"] == true
  end

  def current_profiles
    @current_profiles ||= if use_hubcli?
      node.ws1_device_attributes["DeviceProfiles"] || []
    else
      UberHelpers::MacUtils.get_installed_profiles.fetch("_computerlevel", []).map do |profile|
        profile.merge({
          "Status" => "ConfirmedInstall",
          "Name" => profile["ProfileDisplayName"].split("/V_")[0].split("--")[-1].strip
        })
      end
    end
  end

  def assigned_profiles
    if @assigned_profiles.nil?
      profs = node["cpe_profiles_workspaceone"]
        .to_hash
        .reject { |k, _| CONFIG_KEYS.include?(k) }
        .values
        .map { |p| {payload: p, hash: hash_payload(p), id: process_identifier(p), name: nil} }

      profs.each do |profile|
        hashed_name = "#{profile[:id]}:#{profile[:hash]}"
        profile[:payload]["PayloadIdentifier"] = hashed_name
        profile[:name] = hashed_name
      end

      @assigned_profiles = profs
    end
    @assigned_profiles
  end

  def forced_profiles
    @forced_profiles ||= node["cpe_profiles_workspaceone"].fetch(
      "forced_profiles", []
    ).uniq
  end

  def remote_profiles
    @remote_profiles ||= {"device": [], "user": []}.merge(
      node["cpe_profiles_workspaceone"].fetch("remote_profiles", {})
    )
  end

  def profiles
    @profiles ||= assigned_profiles + remote_profiles.values.flatten.uniq
  end

  def process_identifier(profile)
    identifier = profile["PayloadIdentifier"]
    unless identifier.start_with?(prefix)
      error_string = "#{identifier} is an invalid profile identifier. The" +
           "identifier must start with #{prefix}!"
      fail Chef::Exceptions::ConfigurationError, error_string
    end
    identifier
  end

  def hash_payload(profile)
    payloads = profile["PayloadContent"]
    str = ""
    payloads.sort_by { |p| p.keys.sort.join("") }.each do |payload|
      payload.keys.sort.each do |k|
        next if k == "PayloadUUID" # The UUID can change even if the content remains the same. The hash is our true unique ID.

        str += "#{k}:#{payload[k]}"
      end
    end
    Digest::MD5.hexdigest(str)
  end

  def __cleanup
    @__cleanup ||= (node["cpe_profiles_workspaceone"]["__cleanup"] || []).uniq
  end

  def find_profiles_to_remove
    to_install = assigned_profiles.map { |p| p[:name] }
    current_profiles
      .select { |p| p["Name"].start_with?(prefix) || __cleanup.include?(p["Name"]) }
      .select { |p| p["Status"] == "ConfirmedInstall" || p["Status"] == "UnConfirmedInstall" }
      .reject { |p| to_install.include?(p["Name"]) }
      .map { |p| p["Name"] }
  end
end

action :run do
  return if prefix.nil?

  lambda_parameters = {
    remote_install_requested: !use_hubcli?,
    skip_creation: false
  }

  profiles.each do |profile|
    if profile.is_a?(Hash)
      name = profile[:name]
      lambda_parameters[:skip_creation] = false
      source = "chef"
    elsif profile.is_a?(String)
      name = profile
      profile = {
        name: name,
        payload: nil
      }
      lambda_parameters[:skip_creation] = true
      source = "ws1"
    else
      next
    end

    existing_assignment = current_profiles.select { |p| p["Name"] == name }
    existing_install = existing_assignment.select { |p| p["Status"] == "ConfirmedInstall" }
    assigned = existing_assignment.length > 0
    installed = existing_install.length > 0
    forced = forced_profiles.include?(name)
    profile_type = remote_profiles["user"].include?(name) ? "user" : "device"
    lambda = []
    hubcli = []
    use_lambda = false

    if ((!use_hubcli? && assigned && !installed) ||                            # Use lambda to install an assigned profile.
      (!use_hubcli? && assigned && forced) ||                                  # Use lambda to reinstall an assigned, forced profile.
      (!use_hubcli? && !assigned && forced && source == "ws1") ||              # Use lambda to attempt to install an unassigned profile, if we don't know hubcli assignments and it is a forced ws1 profile.
      (!assigned && source == "chef"))                                         # Use lambda to create, assign, and possibly install a new chef-generated profile

      use_lambda = true
      lambda = ["assign"]
      lambda.prepend("create") unless lambda_parameters[:skip_creation]
      lambda.append("install") unless use_hubcli?
    end

    if use_hubcli?
      hubcli = ["install"]
      node.default["cpe_workspaceone"]["mdm_profiles"]["profiles"][profile_type] += [name]
      node.default["cpe_workspaceone"]["mdm_profiles"]["profiles"]["#{profile_type}_forced"].append(name) if forced
    end

    Chef::Log.info(
      "cpe_profiles_workspaceone[#{name}] assigned: #{assigned}, installed: #{installed}, forced: #{forced}, dispatch: hubcli:#{hubcli}, lambda:#{lambda}"
    )
    Chef::Log.debug("cpe_profiles_workspaceone[#{name}] source: #{source}, type: #{profile_type}")

    node.install_profile_via_lambda(profile, parameters: lambda_parameters) if use_lambda
  end
end

action :clean_up do
  return if prefix.nil?

  find_profiles_to_remove.each do |hashed_name|
    Chef::Log.info("#{hashed_name} - dispatch: lambda:[\"uninstall\"]")
    node.remove_profile_via_lambda(hashed_name)
  end
end
