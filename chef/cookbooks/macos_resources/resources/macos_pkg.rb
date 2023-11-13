# SPDX-FileCopyrightText: Chef Software Inc.
# SPDX-FileCopyrightText: Gusto, Inc.
#
# SPDX-License-Identifier: Apache-2.0

# Author:: Joshua Timberman (<jtimberman@chef.io>)
# Author:: William Theaker (<william.theaker+chef@gusto.com>)

# Adapated from dmg_package

# Cookbook:: macos_resources
# Resource:: macos_pkg

unified_mode true

provides :macos_pkg
resource_name :macos_pkg
default_action :install

property :checksum, String,
  description: "The SHA-256 checksum of the package file to download."

property :file, String,
  description: "The absolute path to the package file on the local system."

property :headers, Hash,
  description: "Allows custom HTTP headers (like cookies) to be set on the `remote_file` resource.",
  desired_state: false

property :package_id, String,
  description: "The package ID registered with `pkgutil` when a `pkg` or `mpkg` is installed.",
  required: true

property :source, String,
  description: "The remote URL used to download the package file, if specified."

property :target, String,
  description: "The device to install the package on.",
  default: "/"

property :version, String,
  description: "The package ID version. This property is optional unless updating an existing package."

load_current_value do |new_resource|
  current_version = pkg_version(new_resource.package_id)
  desired_version = new_resource.version.nil? ? 0 : new_resource.version

  if current_version.nil? || Gem::Version.new(desired_version) > Gem::Version.new(current_version)
    current_value_does_not_exist!
  else
    Chef::Log.debug("Package is already installed. Try \"sudo pkgutil --forget '#{new_resource.package_id}'\"")
  end
end

def pkg_version(pkg_identifier)
  @pkg_version ||= begin
    pkg_info = shell_out("/usr/sbin/pkgutil --pkg-info-plist '#{pkg_identifier}'")
    pkg_info.error? ? nil : Plist.parse_xml(pkg_info.stdout)["pkg-version"]
  end
end

action_class do
  # @return [String] the path to the pkg file
  def pkg_file
    @pkg_file ||= if new_resource.file.nil?
      uri = URI.parse(new_resource.source)
      filename = ::File.basename(uri.path)
      "#{Chef::Config[:file_cache_path]}/#{filename}"
    else
      new_resource.file
    end
  end
end

action :install, description: "Installs the pkg." do
  if new_resource.source.nil? && new_resource.file.nil?
    raise "Must provide either a file or source property for macos_pkg resources."
  end

  if current_resource.nil?
    if new_resource.source
      remote_file pkg_file do
        source new_resource.source
        headers new_resource.headers if new_resource.headers
        checksum new_resource.checksum if new_resource.checksum
      end
    end

    execute "installer -pkg #{pkg_file} -target #{new_resource.target}"
  end
end
