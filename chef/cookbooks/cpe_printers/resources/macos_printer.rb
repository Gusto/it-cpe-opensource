# SPDX-FileCopyrightText: Gusto, Inc.
#
# SPDX-License-Identifier: Apache-2.0

# Cookbook:: cpe_printers
# Resource:: macos_printer

resource_name :macos_printer
unified_mode true
provides :macos_printer, os: "darwin"
default_action :create

description "Manages printers via CUPS."

property :description, String, description: "A human-readable name like '2nd floor copier'."

property :location, String, description: "Physical location like building or floor number."

property :printer_name, String, description: "If different from resource name.", name_property: true

property :shared, [true, false],
  description: "Whether or not the printer is shared.",
  default: false

property :uri, String

load_current_value do |new_resource|
  Chef::Log.debug("Existing printers: #{existing_printers}")
  printer = clean_name(new_resource.printer_name)
  current_value_does_not_exist! unless existing_printers.include?(printer)
  printer_name printer
  location existing_printers[printer]["Location"]
  shared existing_printers[printer]["Shared"] == "Yes"
  uri existing_printers[printer]["DeviceURI"]
end

def clean_name(printer_name)
  # man lpstat: CUPS allows printer names to contain any printable character except SPACE, TAB, "/", and "#".
  # Strip those characters and replace spaces with underscores.
  # Ex: "Copier #1 (Paris) 2/4" -> Copier_1_(Paris)_24
  @clean_name ||= printer_name.tr(" ", "_").delete("#").delete("/")
end

def existing_printers
  @existing_printers ||= begin
    existing_printers = {}
    return existing_printers unless ::File.exist?(CUPS_CONFIG)

    cups = ::File.read(CUPS_CONFIG)
    cups.split("\n").each do |line|
      if /<Printer .*?>/.match(line)
        section = cups.split(line).last.split("</Printer>").first

        device = [
          "DeviceURI",
          "Info",
          "Location",
          "Shared",
        ].map { |k| [k, section[/#{k} (.*)/, 1]] }.to_h
        device = { line.split("<Printer ").last.split(">").first => device }

        existing_printers = device.merge(existing_printers)
      end
    end
    existing_printers
  end
end

action_class do
  CUPS_CONFIG = "/etc/cups/printers.conf".freeze
  GENERIC_PPD = "/System/Library/Frameworks/ApplicationServices.framework/Versions/A/Frameworks/PrintCore.framework/Resources/Generic.ppd".freeze
  LPADMIN = "/usr/sbin/lpadmin".freeze

  def create_printer
    if new_resource.uri.nil?
      raise "Must provide a URI when creating a new printer."
    end

    printer_name = clean_name(new_resource.printer_name)
    Chef::Log.debug("Converted #{new_resource.printer_name} to #{printer_name}.")

    base_command = ["#{LPADMIN} -p '#{printer_name}' -v #{new_resource.uri} -E"]
    unless new_resource.description.nil?
      base_command += ["-D '#{new_resource.description}'"]
    end

    unless new_resource.location.nil?
      base_command += ["-L '#{new_resource.location}'"]
    end

    unless new_resource.shared.nil?
      base_command += ["-o printer-is-shared=#{new_resource.shared ? 'true' : 'false'}"]
    end

    if new_resource.uri.start_with?("lpd://")
      Chef::Log.warn("LPD printer backends are deprecated and will be removed in a future CUPS release.")
      base_command += ["-P #{GENERIC_PPD}"]
    elsif new_resource.uri.start_with?("ipp://")
      # Generate PPD from AirPrint base PPD
      base_command += ["-m everywhere"]
    else
      raise "Printers using the #{new_resource.uri.split(':')[0]} backend aren't supported."
    end

    command = shell_out(base_command.join(" "))

    if command.exitstatus != 0
      Chef::Log.warn("Failed to add printer: #{command.stderr} / #{command.stdout}")
    else
      shell_out("/usr/sbin/cupsaccept '#{printer_name}' && /usr/sbin/cupsenable '#{printer_name}'")
    end
  end
end

action :create do
  if current_resource
    converge_if_changed :location do
      shell_out("#{LPADMIN} -p '#{new_resource.printer_name}' -L '#{new_resource.location}'")
    end
    converge_if_changed :shared do
      shell_out("#{LPADMIN} -p '#{new_resource.printer_name}' -o printer-is-shared=#{new_resource.shared ? 'true' : 'false'}")
    end
    converge_if_changed :uri do
      shell_out("#{LPADMIN} -p #{new_resource.printer_name} -v '#{new_resource.uri}'")
    end
  else
    unless node.resolvable?(new_resource.uri.split("://")[1])
      Chef::Log.warn("Skipping printer creation since the URI isn't resolvable.")
      return
    end
    converge_by "create printer #{new_resource.printer_name}" do
      create_printer
    end
  end
end

action :delete do
  if current_resource
    converge_by "delete printer #{new_resource.printer_name}" do
      shell_out("#{LPADMIN} -x '#{new_resource.printer_name}'")
    end
  end
end
