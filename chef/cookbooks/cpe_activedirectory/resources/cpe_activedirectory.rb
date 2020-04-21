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
  unbind if unbind?
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

  def unbind?
    node['cpe_activedirectory']['unbind']
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

  def bind
    bind_options = node['cpe_activedirectory']['bind_options']
    options_missing = false
    bind_options.each do |option|
      if option.nil? || option.empty?
        log "cpe_activedirectory binding_option #{option} is missing" do
          level :warn
        end
        options_missing = true
      end
    end

    if options_missing
      return
    end

    if node['cpe_activedirectory']['bind_method'] == 'profile_resource'
      bind_profile(bind_options)
    else
      bind_execute(bind_options)
    end
  end

  def bind_execute(bind_options)
    # Escape everything in case of special characters
    cmd = '/usr/sbin/dsconfigad '\
    "-add \'#{bind_options['HostName']}\' "\
    "-username \'#{bind_options['UserName']}\' "\
    "-password \'#{bind_options['Password']}\' "\
    "-computer \'#{bind_options['ClientID']}\' "\
    "-ou \'#{bind_options['ADOrganizationalUnit']}\' "\
    '-force'

    execute 'Binding to domain' do
      command cmd
      not_if { node.ad_bound?(bind_options['HostName']) }
      only_if { node.ad_reachable?(node['cpe_activedirectory']['bind_ldap_check_hostname']) }
    end
  end

  def bind_profile(bind_options)
    # Build configuration profile and pass it to cpe_profiles
    prefix = node['cpe_profiles']['prefix']
    organization = node['organization'] ? node['organization'] : 'Gusto'
    ad_profile = {
      'PayloadIdentifier' => "#{prefix}.active_directory",
      'PayloadRemovalDisallowed' => true,
      'PayloadScope' => 'System',
      'PayloadType' => 'Configuration',
      'PayloadUUID' => 'DAFCE850-DA94-4C7E-84B1-DA3B070056FA',
      'PayloadOrganization' => organization,
      'PayloadVersion' => 1,
      'PayloadDisplayName' => 'Active Directory',
      'PayloadContent' => [],
    }
    ad_profile['PayloadContent'].push(
      'PayloadType' => 'com.apple.DirectoryService.managed',
      'PayloadVersion' => 1,
      'PayloadIdentifier' => "#{prefix}.active_directory",
      'PayloadUUID' => '40AB1149-CF75-4B06-96E7-7394A5204CF3',
      'PayloadEnabled' => true,
      'PayloadDisplayName' => 'Active Directory',
    )
    bind_options.each do |k, v|
      ad_profile['PayloadContent'][0][k] = v
    end

    node.default['cpe_profiles']["#{prefix}.active_directory"] = ad_profile

    unless node.ad_reachable?(node['cpe_activedirectory']['bind_ldap_check_hostname'])
      log 'cpe_activedirectory cannot communicate to domain - profile will fail to install' do
        level :warn
      end
    end
  end

  def configure
    # Force this into *resource* runtime, not compile time - otherwise this
    # fails after immediate binds due to already_set being nil
    # https://github.com/facebook/chef-utils/blob/master/Compile-Time-Run-Time.md
    ruby_block 'Force code into resource runtime' do
      block do
        bind_options = node['cpe_activedirectory']['bind_options']

        flags_to_run = []

        node['cpe_activedirectory']['options'].each do |root, settings|
          next unless [root, 'all'].include?(new_resource.scope)

          settings.reject { |_k, v| v.nil? }.each do |key, value|
            already_set = already_set?(node.active_directory_state, root, key, value)
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
              only_if { node.ad_bound?(bind_options['HostName']) }
            end
          end
        end
      end
    end
  end

  def shell_format(value)
    if value.is_a?(Array)
      "'#{value.join(',')}'"
    elsif [true, false].include?(value)
      value ? 'enable' : 'disable'
    else
      value.to_s
    end
  end

  def unbind
    unless node.ad_reachable?(node['cpe_activedirectory']['bind_ldap_check_hostname'])
      log 'cpe_activedirectory cannot communicate to domain - will not attempt to force unbind' do
        level :warn
        return
      end
    end

    if node['cpe_activedirectory']['unbind_method'] == 'profile_resource'
      unbind_profile
    else
      unbind_execute
    end
  end

  def unbind_execute
    username_to_check = node['cpe_activedirectory']['bind_options']['UserName']
    unless username_to_check.nil?
      execute 'Force unbinding to domain' do
        command '/usr/sbin/dsconfigad -force -remove -u cpe -p fakepass'
        not_if { node.ad_healthy?(username_to_check) }
      end
    end
  end

  def unbind_profile
    username_to_check = node['cpe_activedirectory']['bind_options']['UserName']
    prefix = node['cpe_profiles']['prefix']
    unless username_to_check.nil?
      osx_profile 'Remove Active Directory profile' do
        identifier "#{prefix}.active_directory"
        action :remove
        not_if { node.ad_healthy?(username_to_check) }
      end
    end
  end
end
