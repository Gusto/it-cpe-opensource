#
# Cookbook Name:: cpe_activedirectory
# Resources:: cpe_activedirectory
#
#
#
# Gusto CPE Chef Cookbooks
# Copyright 2019 ZenPayroll, Inc., dba Gusto
#
# This product includes software developed by
# ZenPayroll, Inc., dba Gusto (http://www.gusto.com/).
#

require 'mixlib/shellout'

resource_name :cpe_activedirectory
default_action :run
property :scope, default: 'all'

def already_set?(root, key, value)
  flag_to_profile_map = node['cpe_activedirectory']['flag_to_profile_map']
  profile_root = root.split('_').map(&:capitalize).join(' ')
  profile_key = flag_to_profile_map[root][key]
  return nil if profile_key.nil?

  return nil if node.dsconfigad_profile.nil?

  root_hash = node.dsconfigad_profile[profile_root]
  return nil if root_hash.nil?

  root_hash[profile_key] == value
end

def shell_format(value)
  if value.is_a? Array
    "'#{value.join(',')}'"
  elsif [true, false].include? value
    value ? 'enable' : 'disable'
  else
    value.to_s
  end
end

action :run do
  return unless node['cpe_activedirectory']['configure']

  flags_to_run = []

  node['cpe_activedirectory']['options'].each do |root, settings|
    next unless [root, 'all'].include? new_resource.scope

    settings.reject { |_k, v| v.nil? }.each do |key, value|
      already_set = already_set?(root, key, value)
      if already_set.nil?
        log "cpe_activedirectory option #{key} is not supported" do
          level :warn
        end
        next
      elsif !already_set
        flags_to_run << "-#{key} #{shell_format(value)}"
      end
    end
  end

  flags_to_run.each do |flag|
    cmd = "/usr/sbin/dsconfigad #{flag}"
    if node['cpe_activedirectory']['what_if_execution']
      log "Would have run '#{cmd}'" do
        level :info
      end
    else
      cmd = Mixlib::ShellOut.new(cmd)
      cmd.run_command
      cmd.error!
    end
  end
end
