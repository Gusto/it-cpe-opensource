# Cookbook Name:: cpe_anyconnect
# Resources:: cpe_anyconnect
#
# Gusto CPE Chef Cookbooks
# Copyright 2019 ZenPayroll, Inc., dba Gusto
#
# This product includes software developed by
# ZenPayroll, Inc., dba Gusto (http://www.gusto.com/).
#
# This source code is licensed under the Apache 2.0 license found in the
# LICENSE file in the root directory of this source tree.
#

require 'xmlsimple'
require 'nokogiri'

resource_name :cpe_anyconnect
provides :cpe_anyconnect
default_action :manage

WINDOWS_DIR =  "c:\\ProgramData\\Cisco\\Cisco AnyConnect Secure Mobility Client\\".freeze
MACOS_DIR = "/opt/cisco/anyconnect/".freeze

action_class do
  def shim_path
    node['cpe_anyconnect']['shim']['script_path']
  end

  def root_dir
    if windows?
      WINDOWS_DIR
    elsif macos?
      MACOS_DIR
    else
      raise "Unsupported OS"
    end
  end

  def server_profile_dir
    if windows?
      subd = "Profile"
    elsif macos?
      subd = "profile"
    end

    ::File.join(root_dir, subd)
  end

  def server_profile_path(servername)
    filename = servername.gsub(' ', '_').strip + '.xml'

    ::File.join(server_profile_dir, filename)
  end

  def global_profile_path
    ::File.join(root_dir, '.anyconnect_global')
  end

  def compact(iter)
    unless iter.respond_to?(:compact)
      return nil if iter.nil? || (iter.respond_to?(:empty?) && iter.empty?)
      return iter
    end

    i = iter.dup

    if i.is_a?(Hash)
      if i.keys.include?('content') && i['content'].nil?
        i = nil
      else
        i = i.map { |k, v| [k, compact(v)] }.to_h.compact
      end
    else
      i = i.map { |v| compact(v) }.compact
    end

    if i.nil? || i.empty?
      nil
    else
      i.compact
    end
  end

  def schema
    f = ::File.join(server_profile_dir, 'AnyConnectProfile.xsd')
    @schema ||= Nokogiri::XML::Schema(::File.read(f))
  end

  def generate_profile(root, prefs)
    p = {
      root => [{
        "xmlns" => "http://schemas.xmlsoap.org/encoding/",
        "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
        "xsi:schemaLocation" => "http://schemas.xmlsoap.org/encoding/ AnyConnectProfile.xsd",
      }.merge(compact(prefs))]
    }
    XmlSimple.xml_out(p, 'keeproot' => true, 'suppressempty' => true)
  end

  def global_profile
    profile = generate_profile('AnyConnectPreferences', node.default['cpe_anyconnect']['global_preferences'])
    {global_profile_path => profile}
  end

  # Returns a hash of { filename: xmlstring }
  def server_profiles
    profile = generate_profile('AnyConnectProfile', node.default['cpe_anyconnect']['server_preferences'])
    {server_profile_path('all endpoints') => profile}
  end
end

action :manage do
  return unless node['cpe_anyconnect']['enabled']

  unless Dir.exist?(root_dir)
    Chef::Log.warn('cpe_anyconnect called on system without a healthy/existing anyconnect install')
    return
  end

  profiles = server_profiles.merge(global_profile)

 # This, or a third party "managed_directory" resource
  installed_profiles = Dir.glob(::File.join(server_profile_dir, "*.xml"))
  installed_profiles.each do |filepath|
    next if profiles.keys.include?(::File.basename(filepath))

    file filepath do
      action :delete
    end
  end

  profiles.each do |filename, prefs|
    doc = Nokogiri::XML(prefs)
    validation = schema.validate(doc)
    is_valid = schema.valid?(doc)

    log "AnyConnectProfile Validation" do
      message is_valid ? "#{filename}: valid profile" : "#{validation.join('  ||  ')}"
      level :info
    end

    unless is_valid
      if node['cpe_anyconnect']['validation']['strict']
        raise "Invalid AnyConnect Profile #{filename}! #{validation.join('  ||  ')}"
      end

      unless node['cpe_anyconnect']['validation']['write_anyways']
        log "Refusing to write invalid AnyConnect profiles" do
          level :warn
        end
        return
      end
    end

    template filename do
      variables({'profile' => prefs})
      source 'header.xml.erb'
      mode '0644'
    end
  end
end

action :install_shortcut_shim do
  return unless node['cpe_anyconnect']['enabled']
  return unless node['cpe_anyconnect']['shim']['enabled']

  template shim_path do
    source 'shim.sh.erb'
    owner 'root'
    group 'admin'
    mode '0755'
    action :create
    variables (node['cpe_anyconnect']['shim'])
  end

  node.default['cpe_shims']['shims'][node['cpe_anyconnect']['shim']['command_name']] = {
    'content' => "#{shim_path} \"$@\"",
    'path' => "/usr/local/bin/#{node['cpe_anyconnect']['shim']['command_name']}",
    'shebang' => '#!/bin/bash'
  }
end

action :uninstall_shortcut_shim do
  file shim_path do
    action :delete
  end

  node.default['cpe_shims']['shims'] = node.default['cpe_shims']['shims']
    .reject { |name, _| name == node['cpe_anyconnect']['shim']['command_name'] }
end
