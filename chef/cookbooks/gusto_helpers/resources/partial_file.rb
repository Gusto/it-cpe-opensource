# SPDX-FileCopyrightText: Gusto, Inc.
#
# SPDX-License-Identifier: Apache-2.0

# Cookbook:: gusto_helpers
# Resources:: partial_file

unified_mode true

provides :partial_file
resource_name :partial_file
default_action :create

property :managed_content, String,
  required: true,
  description: "Content to append or remove."

property :path, String, name_property: true

load_current_value do
  current_value_does_not_exist! unless ::File.exist?(path)
end

action_class do
  def current_content
    @current_content ||= if current_resource
      ::File.binread(new_resource.path)
    end
  end
end

action :create do
  new_content = new_resource.managed_content

  if current_resource
    if current_content.include?(new_content)
      Chef::Log.debug("File already includes managed_content. Skipping.")
      new_content = current_content
    else
      Chef::Log.debug("Writing new managed_content to #{new_resource.path}.")
      new_content = current_content << "#{new_content}\n"
    end
  end

  file new_resource.path do
    content new_content
  end
end

action :delete do
  if current_resource
    content_array = current_content.split(new_resource.managed_content)

    file new_resource.path do
      content content_array.join("")
      action :create
    end
  end
end
