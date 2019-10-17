# frozen_string_literal: true
#
#
# Cookbook Name:: cpe_yo
# Resources:: default
#
# Gusto CPE Chef Cookbooks
# Copyright 2019 ZenPayroll, Inc., dba Gusto
#
# This product includes software developed by
# ZenPayroll, Inc., dba Gusto (http://www.gusto.com/).
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

# This is captured straight from running the Yo binary and must be
# updated manually.
# Reference for properties and the arguments_hash hash.

#   -t, --title:
#       Title for notification. REQUIRED.
#   -s, --subtitle:
#       Subtitle for notification.
#   -n, --info:
#       Informative text.
#   -b, --action-btn:
#       Include an action button, with the button label text supplied to this argument.
#   -a, --action-path:
#       Application to open if user selects the action button. Provide the full path as the argument. This option only does something if -b/--action-btn is also specified.
#   -B, --bash-action:
#       Bash script to run. Be sure to properly escape all reserved characters. This option only does something if -b/--action-btn is also specified. Defaults to opening nothing.
#   -o, --other-btn:
#       Alternate label for cancel button text.
#   -i, --icon:
#       Complete path to an alternate icon to use for the notification.
#   -c, --content-image:
#       Path to an image to use for the notification's :contentImage property.
#   -z, --delivery-sound:
#       The name of the sound to play when delivering or :None. The name must not include the extension, nor any path components, and should be located in '/Library/Sounds' or '~/Library/Sounds'. (Defaults to the system's default notification sound). See the README for more info.
#   -d, --ignores-do-not-disturb:
#       Set to make your notification appear even if computer is in do-not-disturb mode.
#   -l, --lockscreen-only:
#       Set to make your notification appear only if computer is locked. If set, no buttons will be available.
#   -p, --poofs-on-cancel:
#       Set to make your notification :poof when the cancel button is hit.

require 'date'
require 'cfpropertylist'

# yo_launchd.py and the launchd definition use these definitions -
# if you're hacking this, change them there too.
PRIVATE_LIB = '/usr/local/lib/yo'.freeze
PUBLIC_LIB = "/Users/#{node.console_user}/Library/Yo".freeze

ARGS = {
   title: [String, {required: true, name_property: true}],
   subtitle: [String],
   info: [String],
   action_btn: [String],
   action_path: [String],
   bash_action: [String],
   other_btn: [String],
   icon: [String],
   content_image: [String],
   delivery_sound: [String],
   ignores_do_not_disturb: [[true, false]],
   lockscreen_only: [[true, false]],
   poofs_on_cancel: [[true, false]],
}.freeze

FILE_ARGS = [
  :content_image,
  :conditional_script,
  :bash_action,
  :delivery_sound,
  :icon
].freeze

resource_name :cpe_yo
provides :cpe_yo
default_action :send

ARGS.each do |name, args|
  args[1].nil? ? property(name, args[0]) : property(name, args[0], **args[1])
end

property :conditional_script, String
property :at, DateTime, default: DateTime.now


action_class do
  def run_yo
    cmd_str = "#{node['cpe_yo']['yo_binary']} #{command_line_arguments}"
    log "./yo #{cmd_str}" do
      level :debug
    end
    full_cmd_str = "/usr/bin/su -l #{node.console_user} -c \"#{cmd_str}\""
    cmd = Mixlib::ShellOut.new(full_cmd_str)
    cmd.run_command
    cmd.error!
    cmd
  end

  def run_launchd
    cmd = Mixlib::ShellOut.new("/usr/local/lib/yo/yo_launchd.py")
    cmd.run_command
    cmd.error!
    cmd
  end

  def configure_base_directories
    directory PRIVATE_LIB do
      not_if { ::Dir.exist? PRIVATE_LIB }
      owner node.console_user
      recursive true
      action :nothing
    end.run_action(:create)

    directory PUBLIC_LIB do
      not_if { ::Dir.exist? PUBLIC_LIB }
      owner node.console_user
      mode '777'
      action :nothing
    end.run_action(:create)

    file receipts_path do
      not_if { ::File.exist? receipts_path }
      owner node.console_user
      mode '777'
      content Hash.new.to_plist
      action :nothing
    end.run_action(:create)

    file log_path do
      not_if { ::File.exist? log_path }
      owner node.console_user
      mode '777'
      content "[#{DateTime.now.to_s}] Log Created"
      action :nothing
    end.run_action(:create)

    FILE_ARGS.each do |arg|
      file_lib = "#{PRIVATE_LIB}/#{arg}s"
      directory file_lib do
        not_if { ::Dir.exist? file_lib }
        action :nothing
      end.run_action(:create)
    end
  end

  def launchd_path
    "#{PRIVATE_LIB}/yo_launchd.py"
  end

  def receipts_path
    "#{PUBLIC_LIB}/.receipts"
  end

  def schedule_path
    "#{PRIVATE_LIB}/schedule.plist"
  end

  def log_path
    "#{PRIVATE_LIB}/launchd.log"
  end

  def configure_yo
    configure_base_directories

    cookbook_file launchd_path do
      source 'yo_launchd.py'
      owner 'root'
      group 'admin'
      mode '0755'
      cookbook 'cpe_yo'
      action :nothing
    end.run_action(:create)

    node.default['cpe_launchd']["com.#{node['organization']}.chef.yo.v2"] = \
    {
      'program_arguments' => ['/usr/local/lib/yo/yo_launchd.py'],
      'limit_load_to_session_type' => ['Aqua'],
      'standard_error_path' => log_path,
      'standard_out_path' => log_path,
      'as_console_user' => true,
      'username' => 'root',
      'type' => 'agent'
    }.merge(node['cpe_yo']['launchd'] || {})

    file schedule_path do
      content (node['cpe_yo']['schedule'] || {}).to_plist
    end
  end

  def reset_yo
    [PRIVATE_LIB, PUBLIC_LIB].each do |lib|
      directory lib do
        action :delete
        recursive true
      end.run_action(:delete)
    end

    configure_base_directories
  end

  def shell_format(arg, val)
    shell_arg = "--#{arg.to_s.tr('_', '-')}"

    if FILE_ARGS.include?(arg) && arg == :delivery_sound
      shell_val = " '#{val.split('.')[0..-2].join('.')}'"
    elsif FILE_ARGS.include?(arg) && arg != :delivery_sound
      shell_val = " '/usr/local/lib/yo/#{arg}s/#{val}'"
    elsif val.class == String
      shell_val = " '#{val}'"
    elsif [TrueClass, FalseClass].include?(val.class)
      shell_val = ''
    elsif val.class == Array
      shell_val = " '#{val.map(&:strip).join(',')}'"
    else
      raise "Invalid yo argument #{val} for #{a}"
    end

    "#{shell_arg}#{shell_val}"
  end

  def create_files
    args = FILE_ARGS
      .map { |arg| [arg, new_resource.send(arg)] }.to_h
      .reject { |_, val| val.nil? }
    configure_base_directories unless args.empty?

    args.each do |arg, val|
      if arg == :delivery_sound
        path = "/Users/#{node.console_user}/Library/Sounds/#{val}"
      else
        path = "/usr/local/lib/yo/#{arg}s/#{val}"
      end

      cookbook_file path do
        source "#{arg}s/#{val}"
        owner 'root'
        group 'admin'
        mode '0755'
        not_if { val.nil? }
        cookbook 'cpe_yo'
        action :nothing
      end.run_action(:create)
    end
  end

  def arguments_hash
    @arguments_hash ||= ARGS.keys
      .map { |arg| [arg, new_resource.send(arg)] }
      .to_h
  end

  def command_line_arguments
    @cli_args ||= arguments_hash
      .reject { |_, val| val.nil? }
      .sort_by { |arg, val| arg }
      .map { |arg, val| shell_format(arg, val) }
      .join(' ')
  end

  def schedule_key
    command_line_arguments
  end
end


action :configure do
  return unless node['cpe_yo']['configure']
  return if node['cpe_yo']['user_alert_blacklist'].include? node.console_user

  configure_yo
end


action :send do
  return unless node['cpe_yo']['configure']
  return if node['cpe_yo']['user_alert_blacklist'].include? node.console_user

  create_files

  if new_resource.conditional_script
    cmd = Mixlib::ShellOut.new(
      "/usr/local/lib/yo/conditional_scripts/#{new_resource.conditional_script}"
    )
    cmd.run_command
    begin
      cmd.error!
    rescue Mixlib::ShellOut::ShellCommandFailed
      log 'Skipped Yo alert' do
        message "Skipped Yo alert '#{new_resource.title}': conditional failed"
        level :warn
      end
      return
    end
  end

  run_yo
end


action :schedule do
  return unless node['cpe_yo']['configure']
  return if node['cpe_yo']['user_alert_blacklist'].include? node.console_user

  raise 'You must provide a conditional script or an at parameter!' unless \
    new_resource.conditional_script || new_resource.at

  create_files
  new_resource.at = new_resource.at.nil? ? DateTime.now : new_resource.at
  new_resource.at = new_resource.at.new_offset(0)

  if node.default['cpe_yo']['schedule'].nil?
    node.default['cpe_yo']['schedule']['notifications'] = {
      'notifications': {},
      'conditions': {}
    }
  end

  node.default['cpe_yo']['schedule']['notifications'][schedule_key] = \
    new_resource.at
  node.default['cpe_yo']['schedule']['conditional_scripts'][schedule_key] = \
    new_resource.conditional_script if new_resource.conditional_script
end


action :trigger_scheduled do
  return unless node['cpe_yo']['configure']
  return if node['cpe_yo']['user_alert_blacklist'].include? node.console_user

  run_launchd
end

action :reset do
  return unless node['cpe_yo']['configure']
  return if node['cpe_yo']['user_alert_blacklist'].include? node.console_user

  reset_yo
end
