# SPDX-FileCopyrightText: Gusto, Inc.
#
# SPDX-License-Identifier: Apache-2.0

# Cookbook:: cpe_mdm_profiles
# Resource:: zap_macos_mdm_profile

resource_name :zap_macos_mdm_profile
unified_mode true
provides :zap_macos_mdm_profile, os: "darwin"
default_action :cleanup

description "Removes macOS MDM profiles installed on a devices, but not defined as macos_mdm_profile resources during a current Chef run."

use "_partial/_http_request"

property :label, String, required: true,
  description: "Profile name with prefix, like foocorp.Firefox, to remove old versions of."

action :cleanup do
  description "Checks for the existence of a profile and removes it via a middleware."

  chef_managed_profiles = []
  with_run_context :root do
    # Build an array of macos_mdm_profile resources that have already been processed in the current run.
    # We don't need to check resource.action, since we can ignore profiles we're already gonna remove.
    # Arguments passed to filtered_collection define whether to include the resource state in the collection.
    # Setting skipped to false lets us filter out resources with :nothing actions.
    Chef.run_context.action_collection.filtered_collection(skipped: false).select { |rec| rec.new_resource.resource_name == :macos_mdm_profile }.each do |profile|
      chef_managed_profiles += [profile.new_resource.profile_name]
    end
  end
  Chef::Log.debug("Found Chef-managed profiles: #{chef_managed_profiles}")

  installed_profiles_copy = ProfileHelpers::MacUtils.installed_profile_names
  (installed_profiles_copy - chef_managed_profiles).each do |profile|
    Chef::Log.debug("Considering profile #{profile}")
    if /^(#{new_resource.label}):([0-9a-fA-F]*)/.match?(profile)
      converge_by "remove profile #{profile}" do
        Chef::Log.debug("Installed profile not in Chef run: #{profile}. Attempting to remove.")
        send_profile_request("remove", profile)
      end
    end
  end
end
