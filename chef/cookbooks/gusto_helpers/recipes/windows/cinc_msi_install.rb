# SPDX-FileCopyrightText: Gusto, Inc.
#
# SPDX-License-Identifier: Apache-2.0

# Cookbook:: gusto_helpers
# Recipes:: windows/cinc_msi_install

return unless windows?

CINC_CLIENT_SHA256 = "238032b3f9fc24ee1b2c858e069b0043746218140d5fb3dd07123d632b7fb5bf".freeze
CINC_VERSION = "18.2.7".freeze

# We need to use .cleanpath because Chef otherwise mixes forward and back slashes, which Windows hates
msi_path = ChefConfig::PathHelper.join(ChefConfig::PathHelper.cleanpath(Chef::Config[:file_cache_path]), "cinc-#{CINC_VERSION}.msi")

# Cleanup post-upgrade
if Gem::Version.new(node["chef_packages"]["chef"]["version"]) >= Gem::Version.new(CINC_VERSION)
  file msi_path do
    action :delete
  end

  windows_task "Update cinc-client" do
    action :delete
  end

  Chef::Log.info("Cinc Client already at version #{CINC_VERSION}. Skipping update.")
  return
end

remote_file "Cinc Client MSI" do
  path msi_path
  source "https://ftp.osuosl.org/pub/cinc/files/stable/cinc/#{CINC_VERSION}/windows/2012r2/cinc-#{CINC_VERSION}-1-x64.msi"
  checksum CINC_CLIENT_SHA256
  action :create_if_missing
end

# Schedule Cinc update task for fifteen minutes from now
run_time = Time.now + 900

# Cinc can't update itself from within a run, so schedule a task every two hours until success
windows_task "Update cinc-client" do
  command "msiexec.exe /qn /i #{msi_path} ADDLOCAL=\"CincClientFeature,CincSchTaskFeature\""
  run_level :highest
  frequency :minute
  frequency_modifier 120
  start_time run_time.strftime("%H:%M")
end
