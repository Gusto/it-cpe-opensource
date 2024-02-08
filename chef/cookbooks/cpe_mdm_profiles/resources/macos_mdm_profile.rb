# SPDX-FileCopyrightText: Gusto, Inc.
#
# SPDX-License-Identifier: Apache-2.0

# Cookbook:: cpe_mdm_profiles
# Resource:: macos_mdm_profile

resource_name :macos_mdm_profile
unified_mode true
provides :macos_mdm_profile, os: "darwin"
default_action :install

description "Manages macOS profile middleware assignment."

use "_partial/_http_request"

property :label, String,
  description: "Profile name with prefix like foocorp.Firefox. Used with :payload property."

property :payload, Hash,
  description: "Hash containing the PayloadContent of a profile. Used with :label property."

property :profile_name, String,
  description: "The profile's name such as `gcorp.security -- mac_user_passwordpolicy`. Must provide either profile_name or payload. If not specified, uses resource block's name.",
  name_property: true

property :request_parameters, Hash,
  description: "Hash containing parameters to pass along to the middleware at creation. Use with :payload property."

property :scope, String,
  description: "Define the PayloadScope of a profile at creation, either User or System. Also known as (device|user)channel.",
  default: "System"

load_current_value do |new_resource|
  name_hash = hashed_name(new_resource)
  Chef::Log.debug("Calculated hashed_name as #{name_hash}.")
  Chef::Log.debug("installed_profile_names returned #{ProfileHelpers::MacUtils.installed_profile_names}")
  current_value_does_not_exist! unless ProfileHelpers::MacUtils.installed_profile_names.include?(name_hash)
  profile_name name_hash
end

def hash_profile(profile)
  @hash_profile ||= begin
    str = ""
    profile.each do |_, v|
      v.map { |c| str += c.sort.join("") }
    end
    Digest::MD5.hexdigest(str)
  end
end

def hashed_name(new_resource)
  # Hash payload contents before adding UUID and other scaffolding
  @hashed_name ||= begin
    if new_resource.payload.nil?
      new_resource.profile_name
    else
      # If profile_name is nil, calculate hashed name from :payload
      "#{new_resource.label}:#{hash_profile(new_resource.payload)}"
    end
  end
end

def x509_payloads
  [
    "com.apple.security.pem",
    "com.apple.security.pkcs1",
    "com.apple.security.pkcs12",
    "com.apple.security.root",
  ]
end

action :install do
  description "Checks for the existence of a profile and installs it via a middleware."

  new_resource.profile_name = hashed_name(new_resource)
  request = {
    user_scope: new_resource.scope == "User",
  }

  if current_resource
    Chef::Log.debug("Profile #{new_resource.profile_name} appears to already be installed")
    return
  else
    if new_resource.payload.nil?
      Chef::Log.debug("No :payload property supplied. Skipping profile construction.")
      # Proceed directly to install
    else
      # Build profile
      profile_scaffold = {
        "PayloadType" => "Configuration",
        "PayloadContent" => [],
      }

      new_resource.payload.each do |k, v|
        contents = []
        v.each do |c|
          uuid = SecureRandom.uuid
          payload_hash = {
            "PayloadIdentifier" => "com.#{new_resource.label}-#{uuid}",
            "PayloadType" => k,
            "PayloadUUID" => uuid,
            "PayloadVersion" => 1,
          }
          # Transform the top level payload key PayloadContent which is consistent across X.509 profiles
          c["PayloadContent"] = PlistDataTypes::Serialize.new(c["PayloadContent"], "data") if x509_payloads.include?(k)
          contents.push(payload_hash.merge!(c))
        end
        profile_scaffold["PayloadContent"] += contents
      end

      # This gem unavoidably sorts keys
      request["profile"] = Plist::Emit.dump(profile_scaffold)

      if new_resource.request_parameters
        request.merge!(new_resource.request_parameters)
      end
    end

    converge_by "install profile #{new_resource.profile_name}" do
      send_profile_request("install", new_resource.profile_name, request)
    end
  end
end

action :remove do
  description "Checks for the existence of a profile and removes it via a middleware."
  if current_resource
    converge_by "remove profile #{new_resource.profile_name}" do
      Chef::Log.debug("Found #{new_resource.profile_name} in installed profiles. Attempting removal.")
      send_profile_request("remove", hashed_name(new_resource))
    end
  else
    Chef::Log.debug("Didn't find #{new_resource.profile_name} in installed profile.")
  end
end
