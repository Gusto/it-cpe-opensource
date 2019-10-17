#
# Cookbook Name:: cpe_hot_corners
# Resource:: cpe_hot_corners
#
#
#
# Gusto CPE Chef Cookbooks
# Copyright 2019 ZenPayroll, Inc., dba Gusto
#
# This product includes software developed by
# ZenPayroll, Inc., dba Gusto (http://www.gusto.com/).
#
# Authors: Austin Culter, Harry Seeber
# This source code is licensed under the Apache 2.0 license found in the
# LICENSE file in the root directory of this source tree.
#
require 'cfpropertylist'
require 'mixlib/shellout'

resource_name :cpe_hot_corners
default_action :run

HUMAN_READABLE_CORNER = {
  'wvous-tr-corner' => '↗',
  'wvous-tl-corner' => '↖',
  'wvous-br-corner' => '↘',
  'wvous-bl-corner' => '↙'
}.freeze

LOCKFILE = '/var/db/.cpe_hot_corners'

action_class do
  def dock_plist
    binary_plist = CFPropertyList::List.new(
      file: node['cpe_hot_corners']['settings']['dock_plist']
    )
    CFPropertyList.native_types(binary_plist.value)
  end

  def defined_corners
    corners = {}
    dock_plist
      .each { |k, v| corners.merge!(k.to_s => v.to_s) if k.include?('corner') }
    corners
  end

  def null_corners
    defined_corners.select { |_k, v| v == '1' }
  end

  def undefined_corners
    node['cpe_hot_corners']['settings']['corner_ids'] - defined_corners.keys + null_corners.keys
  end

  def safe_execute_stdout(cmd)
    log "safe_execute_stdout: #{cmd}"
    c = Mixlib::ShellOut.new(cmd).run_command
    c.error!
    c.stdout
  end

  def set_forced_corner(corner_id)
    safe_execute_stdout(
      '/usr/bin/defaults write' \
      " #{node['cpe_hot_corners']['settings']['dock_plist']}" \
      " #{corner_id} -int #{node['cpe_hot_corners']['settings']['default_compliant_value']}"
    )
    safe_execute_stdout(
      '/usr/bin/defaults' \
      " write #{node['cpe_hot_corners']['settings']['dock_plist']}" \
      " #{corner_id.gsub('corner', 'modifier')} -int 0"
    )
  end

  def reload_dock
    safe_execute_stdout(
      "/usr/sbin/chown #{node.console_user} #{node['cpe_hot_corners']['settings']['dock_plist']}"
    )
    %w[cfprefsd Dock].each do |process|
      safe_execute_stdout("/usr/bin/killall #{process}")
    end
  end

  def alert_already_sent?
    if ::File.exist?(LOCKFILE)
      (DateTime.now - DateTime.parse(::File.stat(LOCKFILE).mtime.to_s)).to_i < node['cpe_hot_corners']['notification_cadence']
    else
      false
    end
  end

  def enforce_hot_corner(corner_id)
    human_readable = HUMAN_READABLE_CORNER[corner_id]
    if human_readable.nil?
      fail "#{corner_id} is not a valid corner id"
    end

    set_forced_corner(corner_id)
    reload_dock
    cpe_yo 'Locking Hot Corner set' do
      subtitle "Moving the mouse #{human_readable} will lock screen."
      action_btn 'Details'
      action_path '/System/Library/PreferencePanes/Expose.prefPane'
      ignores_do_not_disturb true
    end
    log "Locking Hot Corner was set to #{corner_id} (#{human_readable})"
  end

  def get_best_corner
    options = [node['cpe_hot_corners']['settings']['chosen_corner']] + \
               node['cpe_hot_corners']['settings']['corner_ids']
    options.each do |corner_id|
      if (HUMAN_READABLE_CORNER.keys + undefined_corners).count(corner_id) == 2
        return corner_id
      end
    end
    return nil
  end

  def compliant?
    !(defined_corners.values & node['cpe_hot_corners']['settings']['compliant_values']).empty? ||
    node['cpe_hot_corners']['settings']['compliant_values'].nil? ||
    node['cpe_hot_corners']['settings']['compliant_values'].empty?
  end
end

action :run do
  return unless node['cpe_hot_corners']['configure']
  if compliant?
    log 'Compliant Hot Corner already set'
    return
  end

  corner = get_best_corner

  if node['cpe_hot_corners']['enforce'] && !corner.nil?
    enforce_hot_corner(corner)
  else
    file LOCKFILE do
      content JSON.generate({'when': DateTime.now})
      owner 'root'
      group 'wheel'
      action :nothing
    end

    cpe_yo node['cpe_hot_corners']['configure_title']  do
      info node['cpe_hot_corners']['configure_message']
      action_btn 'Settings'
      action_path '/System/Library/PreferencePanes/Expose.prefPane'
      ignores_do_not_disturb true
      not_if { alert_already_sent? }
      notifies :create, "file[#{LOCKFILE}]", :immediately
    end
  end
end

action :enforce do
  return unless node['cpe_hot_corners']['configure']
  if compliant?
    log 'Compliant Hot Corner already set'
    return
  end

  corner = get_best_corner || node['cpe_hot_corners']['settings']['corner_ids'][0] || HUMAN_READABLE_CORNER.keys[0]
  enforce_hot_corner(corner)
end
