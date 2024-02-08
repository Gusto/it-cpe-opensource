# SPDX-FileCopyrightText: Gusto, Inc.
#
# SPDX-License-Identifier: Apache-2.0

# Cookbook:: gusto_helpers
# Libraries:: node_utils
#

class Chef
  class Node
    def in_shard?(shard_threshold)
      @in_shard ||= node["shard_seed"] % 100 <= shard_threshold
    end

    def rollout_shard(start_date)
      numdays = (Date.today - Date.parse(start_date)).to_i

      if numdays >= 7
        Chef::Log.warn("#{numdays} day outdated shard found at #{caller(2, 1)[0]}")
        shard = 100
      elsif numdays < 0
        shard = 0
      else
        # Start first day of shard at 14%
        shard = ((numdays + 1) / 7.0 * 100).truncate()
      end
      Chef::Log.debug("#{numdays} days since #{start_date} shard start. #{shard}% complete.")
      return shard
    end

    def shard_over_a_week_starting(start_date)
      in_shard?(rollout_shard(start_date))
    end

    def username
      @username ||= begin
        if macos?
          if ChefUtils.virtual?
            ENV["SUDO_USER"]
          elsif ["loginwindow", "_mbsetupuser", "root"].include?(console_user)
            primary_user # Use most recently created admin user
          else
            console_user
          end
        elsif windows?
          node["kernel"]["cs_info"]["user_name"].split("\\")[1]
        elsif linux?
          ENV["SUDO_USER"]
        end
      end
    end

    def homedir
      @homedir ||= begin
        if macos? || linux?
          ::Pathname.new(Etc.getpwnam(username).dir)
        elsif windows?
          ::File.join(ENV["SYSTEMDRIVE"], "Users", username) # Inspired by Facebook's cpe_helpers
        end
      end
    end

    def serial
      @serial ||= begin
        if macos?
          node["hardware"]["serial_number"]
        elsif windows?
          node["dmi"]["system"]["serial_number"]
        end
      end
    end

    private

    def console_user
      @console_user ||= Etc.getpwuid(::File.stat("/dev/console").uid).name
    end

    def primary_user
      # Get username from the highest UID in admin group
      @primary_user ||= Etc.getgrnam("admin").mem
                           .reject { |u| ["root"].include?(u) }
                           .map { |u| Etc.getpwnam(u) }
                           .max_by(&:uid)["name"]
    end
  end
end
