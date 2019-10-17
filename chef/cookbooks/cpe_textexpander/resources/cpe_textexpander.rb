#
#
# Cookbook Name:: cpe_textexpander
# Resource:: cpe_textexpander
#
# Gusto CPE Chef Cookbooks
# Copyright 2019 ZenPayroll, Inc., dba Gusto
#
# This product includes software developed by
# ZenPayroll, Inc., dba Gusto (http://www.gusto.com/).
#
require 'cfpropertylist'
require 'securerandom'

# You'll generally want a custom resource for each platform that provides
# functionality for each specific OS.
resource_name :cpe_textexpander
# The value for "provides" is the actual name of the custom resource that is
# called from your recipes/default.rb file.
# Even though this file is named "cpe_textexpander_darwin" (because it's macOS-only),
# it provides a custom resource that can be called with "cpe_textexpander".
# The "os" is what OSes this resource is supported to run on.
# Chef will throw an error and halt if you call a custom resource on a platform
# that is not supported.
provides :cpe_textexpander, :os => 'darwin'
# You can specify multiple actions for a custom resource, but typically
# you'll only ever need one. This default_action corresponds to the action
# section below.
default_action :configure

action_class do
  def settings_dir
    "/Users/#{node.console_user}/Library/Application Support/TextExpander/Settings.textexpandersettings"
  end

  def managed_snippet_label
    label = node['cpe_textexpander']['managed_snippet_label'] ||
            node['organization'] ||
            'Gusto Managed'
    " (#{label})"
  end

  def read_config(path)
    return {} unless ::File.exist?(path)

    begin
      CFPropertyList.native_types(CFPropertyList::List.new(file: path).value)
    rescue CFFormatError
      return {}
    end
  end

  def generate_path
    uuid = SecureRandom.uuid.strip.upcase
    "#{settings_dir}/group_#{uuid}_1.xml"
  end

  def existing_config
    return @existing_config if @existing_config

    glob = "#{settings_dir}/group_*.xml"
    Dir[glob].each do |path|
      settings = read_config(path)
      return path, settings if settings['name'] == managed_snippet_label
    end
    return generate_path, {}
  end

  def nested_nil?(value)
    if value.respond_to?(:each)
      if value.is_a?(Hash)
        value.reject { |_, v| nested_nil?(v) }.empty?
      else
        value.reject { |v| nested_nil?(v) }.empty?
      end
    else
      value.nil?
    end
  end

  def label_managed_snippets(config)
    config['name'] = managed_snippet_label
    current = config['snippetPlists'].to_a
    return config if current.nil? || current.empty?

    current.each do |snip|
      snip['label'] = (snip['label'] || snip['abbreviation']) + managed_snippet_label
    end

    config['snippetPlists'] = current
    config
  end

  def global_settings
    @global_settings ||=
    node['cpe_textexpander']['global_settings'].reject { |_, v| nested_nil?(v) }
  end

  def snippets_settings
    @snippets_settings ||=
    label_managed_snippets(
      node['cpe_textexpander']['snippets_settings'].reject { |_, v| nested_nil?(v) }
    )
  end
end

action :configure do
  return unless node.macos?
  return unless node['cpe_textexpander']['configure']
  return if ['_mbsetupuser', 'root'].include? node.console_user
  return unless ::Dir.exists?(settings_dir)

  path, settings = existing_config

  file path do
    content snippets_settings.to_plist
    mode 0644
    owner node.console_user
  end

  global_settings.each do |k, v|
    # We only support chef-client 14+
    macos_userdefaults 'update textExpander preferences' do
      domain node['cpe_textexpander']['preference_domain']
      not_if { ['_mbsetupuser', 'root'].include? node.console_user }
      user node.console_user
      key k
      value v
    end
  end
end
