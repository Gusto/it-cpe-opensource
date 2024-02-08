# SPDX-FileCopyrightText: Facebook, Inc.
# SPDX-FileCopyrightText: Gusto, Inc.
#
# SPDX-License-Identifier: Apache-2.0

# Modified from Facebook's cpe_utils cookbook, originally released under the 3-Clause BSD License.

include Chef::Mixin::ShellOut

module Osquery
  include Chef::Mixin::ShellOut

  def self.bin
    if ChefUtils.windows?
      @osquery_bin = ChefConfig::PathHelper.cleanpath("C:/Program Files/osquery/osqueryi.exe")
    else
      @osquery_bin = ""
      [
        "/usr/bin/osqueryi",
        "/usr/local/bin/osqueryi",
      ].each do |path|
        if File.exist?(path)
          @osquery_bin = path
          break
        end
      end
    end
    @osquery_bin
  end

  def self.installed?
    File.exist?(bin)
  end

  # Execute a query
  # @param [string] query
  def self.query(query, suppress_errors: true)
    @query = query.tr("\n", " ")

    unless installed?
      unless suppress_errors
        raise ArgumentError, "osqueryi not found: cannot complete query!"
      end

      Chef::Log.warn("could not find osqueryi")
      return []
    end
    results = []
    begin
      response = shell_out(
         "#{@osquery_bin}",
        "--disable_extensions",
        "--json",
         "#{@query}",
       )
      Chef::Log.debug("Ran osquery command #{response.command}")
      Chef::Log.debug("osquery stderr #{response.stderr}")
      Chef::Log.debug("osquery stdout #{response.stdout}")
      results = JSON.parse(response.stdout.strip)
    rescue JSON::ParserError => e
      Chef::Log.warn("In osquery.rb Error: #{e.message}")
      results = []
      unless suppress_errors
        raise e
      end
    rescue Mixlib::ShellOut::CommandTimeout => e
      Chef::Log.warn("osquery timeout: #{e.message}")
      results = []
      unless suppress_errors
        raise e
      end
    end
    return results
  end
end
