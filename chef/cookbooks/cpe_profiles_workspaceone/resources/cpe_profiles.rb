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
provides :cpe_profiles_workspaceone, :os => 'darwin'
default_action :run

action_class do
  def prefix
    node['cpe_profiles_workspaceone']['prefix']
  end

  def current_profiles
    @_current_profiles ||= node.ws1_device_attributes['DeviceProfiles'] || []
  end

  def assigned_profiles
    if @_assigned_profiles.nil?
      profs = node['cpe_profiles_workspaceone']
        .to_hash
        .reject { |k, _| k == 'prefix' || k == 'lambda_config' }
        .values
        .map { |p| {payload: p, hash: hash_payload(p), id: process_identifier(p), name: nil} }

      profs.each do |profile|
        hashed_name = "#{profile[:id]}:#{profile[:hash]}"
        profile[:payload]['PayloadIdentifier'] = hashed_name
        profile[:name] = hashed_name
      end

      @_assigned_profiles = profs
    end
    @_assigned_profiles
  end

  def process_identifier(profile)
    identifier = profile['PayloadIdentifier']
    unless identifier.start_with?(prefix)
      error_string = "#{identifier} is an invalid profile identifier. The" +
           "identifier must start with #{prefix}!"
      fail Chef::Exceptions::ConfigurationError, error_string
    end
    identifier
  end

  def hash_payload(profile)
    payloads = profile['PayloadContent']
    str = ''
    payloads.sort_by { |p| p.keys.sort.join('') }.each do |payload|
      payload.keys.sort.each do |k|
        next if k == 'PayloadUUID' # The UUID can change even if the content remains the same. The hash is our true unique ID.

        str += "#{k}:#{payload[k]}"
      end
    end
    Digest::MD5.hexdigest(str)
  end

  def find_profiles_to_remove
    to_install = assigned_profiles.map { |p| p[:name] }

    to_remove = current_profiles
      .select { |p| p['Name'].start_with?(prefix) }
      .select { |p| p['Status'] == "ConfirmedInstall" || p['Status'] == "UnConfirmedInstall" }
      .reject { |p| to_install.include?(p['Name']) }
      .map { |p| p['Name'] }

    to_remove = (to_remove + (node['cpe_profiles_workspaceone']['__cleanup'] || [])).uniq
    to_remove
  end
end

action :run do
  assigned_profiles.each do |profile|
    existing_assigned_profile = current_profiles.select { |p| p['Name'] == profile[:name] }

    if existing_assigned_profile.empty?
      Chef::Log.info("Creating and assigning profile via lambda: #{profile[:name]} with payload #{profile[:id]}")
      profile_id = node.install_profile_via_lambda(profile)
    else
      profile_id = existing_assigned_profile[0]['Id']
      Chef::Log.info("Profile #{profile[:id]} with payload #{profile[:hash]} already assigned")
    end
    node.default['cpe_workspaceone']['mdm_profiles']['profiles']['device'] += [profile[:name]]
  end
end

action :clean_up do
  find_profiles_to_remove.each do |hashed_name|
    Chef::Log.info("Removing profile #{hashed_name}")
    node.remove_profile_via_lambda(hashed_name)
  end
end
