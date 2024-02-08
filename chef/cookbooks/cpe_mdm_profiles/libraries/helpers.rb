# SPDX-FileCopyrightText: Gusto, Inc.
#
# SPDX-License-Identifier: Apache-2.0

module ProfileHelpers
  class MacUtils
    def self.node_object
      Chef::Node.get_node_object
    end

    def self.device_profiles
      @device_profiles ||= Plist.parse_xml(shell_out("/usr/bin/profiles show -output stdout-xml").stdout).fetch("_computerlevel", [])
    end

    def self.user_profiles(user: nil)
      @user_profiles ||= begin
        return [] if user.nil?

        Plist.parse_xml(shell_out("/usr/bin/profiles show -output stdout-xml -user \"#{user}\"").stdout).fetch(user, [])
      end
    end

    def self.installed_profiles
      @installed_profiles ||= user_profiles(user: node_object.username) + device_profiles
    end

    def self.installed_profile_names
      @installed_profile_names ||= begin
        profile_names = []
        installed_profiles.each do |profile|
          profile_names += [profile["ProfileDisplayName"]]
        end
        profile_names
      end
    end
  end
end
