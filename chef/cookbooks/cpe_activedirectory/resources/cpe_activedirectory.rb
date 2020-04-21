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
# ZenPayroll, Inc., dba Gusto (https://www.gusto.com/).
#

resource_name :cpe_activedirectory
provides :cpe_activedirectory
default_action :run
property :scope, default: 'all'

action :run do
  bind if bind?
  configure if configure?
end

action_class do # rubocop:disable Metrics/BlockLength
  def bind?
    node['cpe_activedirectory']['bind']
  end

  def configure?
    node['cpe_activedirectory']['configure']
  end

  def bind
    bind_options = node['cpe_activedirectory']['bind_options']
    bind_options.each do |option|
      if option.nil? || option.empty?
        log "cpe_activedirectory binding_option #{option} is missing" do
          level :warn
        end
      end
    end
    # Escape everything in case of special characters
    cmd = '/usr/sbin/dsconfigad '\
    "-add \'#{bind_options['domain_hostname']}\' "\
    "-username \'#{bind_options['binding_username']}\' "\
    "-password \'#{bind_options['binding_password']}\' "\
    "-computer \'#{bind_options['client_id']}\' "\
    "-ou \'#{bind_options['organization_unit']}\' "\
    '-force'

    unless node.ad_reachable?(bind_options['domain_ldap_hostname'])
      log 'cpe_activedirectory cannot communicate to domain' do
        level :warn
      end
      return
    end

    execute 'Binding to domain' do
      command cmd
      not_if { node.ad_bound?(bind_options['domain_hostname']) }
    end
  end

  def configure
    flags_to_run = []
    ad_state = node.active_directory_state

    node['cpe_activedirectory']['options'].each do |root, settings|
      next unless [root, 'all'].include? new_resource.scope

      settings.reject { |_k, v| v.nil? }.each do |key, value|
        already_set = already_set?(ad_state, root, key, value)
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
        execute "Setting Active Directory value #{flag}" do
          command cmd
        end
      end
    end
  end

  def already_set?(ad_state, root, key, value)
    flag_to_profile_map = node['cpe_activedirectory']['flag_to_profile_map']
    profile_root = root.split('_').map(&:capitalize).join(' ')
    profile_key = flag_to_profile_map[root][key]
    return nil if profile_key.nil?

    return nil if ad_state.nil?

    root_hash = ad_state[profile_root]
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
end
