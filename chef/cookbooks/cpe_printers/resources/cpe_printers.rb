#
# Cookbook Name:: cpe_printers
# Resource:: cpe_printers
#
#
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

require 'mixlib/shellout'

resource_name :cpe_printers
default_action :configure
property :printers, [Array, NilClass], default: nil


ATTRIBUTE_TO_LPADMIN_FLAG = {
  'identifier' => '-p',
  'DisplayName' => '-D',
  'Location' => '-L',
  'DeviceURI' => '-v',
  'Model' => '-m',
  'PPDURL' => '-P'
}.freeze


action_class do
  def add_identifier(printer)
    id = printer['DisplayName'].tr(' ', '_').delete('()')
    printer['identifier'] = "#{node['cpe_printers']['prefix']}_#{id}"
    printer
  end

  def enforce_defaults(printer)
    node['cpe_printers']['defaults'].merge(printer)
  end

  def printer_installed?(printer)
    node.printers[printer['identifier']] == printer['DeviceURI'] && \
    ::File.exist?("/private/etc/cups/ppd/#{printer['identifier']}.ppd")
  end

  def prepare_printer_list(printers)
    printers.map(&:to_h)
            .map { |printer| enforce_defaults(printer) }
            .map { |printer| add_identifier(printer) }
  end

  def reset_cups
    slack_notify 'Remediating CUPS...' do
      message "CUPS is broken on *#{node.name}*. Attempting remediation..."
    end

    [
      '/bin/launchctl stop org.cups.cupsd',
      '/bin/cp /etc/cups/cupsd.conf.default /etc/cups/cupsd.conf',
      '/bin/rm /etc/cups/printers.conf',
      '/bin/launchctl start org.cups.cupsd'
    ].each do |cmd|
      c = Mixlib::ShellOut.new(cmd)
      c.run_command
      c.error!
    end
  end

  def install_printer(printer)
    cmd = '/usr/sbin/lpadmin -E'
    printer.each do |k, v|
      flag = ATTRIBUTE_TO_LPADMIN_FLAG[k]
      flag = flag.nil? ? "-o #{k.strip}=" : "#{flag.strip} "
      cmd += " #{flag}'#{v.to_s.strip}'"
    end

    [
      cmd,
      "/usr/sbin/cupsenable #{printer['identifier']}",
      "/usr/sbin/cupsaccept #{printer['identifier']}"
    ].each do |c|
      run = Mixlib::ShellOut.new(c).run_command
      run.error!
    end
  end

  def install_printers(printers)
    printers.each do |printer|
      next if printer_installed?(printer)

      begin
        install_printer(printer)
      rescue Mixlib::ShellOut::ShellCommandFailed => e
        if e.message.include?('lpadmin') && \
          node['cpe_printers']['reset_cups_if_neccessary'] && \
          !node['cpe_printers']['cups_reset_attempted']
          node.default['cpe_printers']['cups_reset_attempted'] = true
          reset_cups
          install_printers(printers)
        else
          raise e
        end
      end
    end
  end
end


action :configure do
  return unless node['cpe_printers']['configure']

  printers = prepare_printer_list(
    (new_resource.printers || node['cpe_printers']['printers'])
  )

  install_printers(printers)
end


action :clean_up do
  return unless node['cpe_printers']['configure']

  if new_resource.printers.nil?
    identifiers = prepare_printer_list(node['cpe_printers']['printers'])
      .map { |x| x['identifier'] }

    printers_to_delete = \
      node.printers.keys
        .select { |k| k.start_with?(node['cpe_printers']['prefix']) && !identifiers.include?(k) }

    if node['cpe_printers']['delete_mcx_printers']
      printers_to_delete += \
        node.printers.keys.select { |k| k.match(/mcx_\d*/) }
    end
  else
    printers_to_delete = new_resource.printers
  end

  printers_to_delete.each do |printer|
    cmd = Mixlib::ShellOut.new("/usr/sbin/lpadmin -x #{printer}")
    cmd.run_command
  end
end
