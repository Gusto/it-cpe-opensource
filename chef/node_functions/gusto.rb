# Cookbook Name:: cpe_utils
# Library::node_functions
#
#
#
# Copyright (c) 2019-present, Gusto, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#



class Chef
  # Custom Extensions of the node object.
  class Node
    def console_uid
      return nil unless macos?

      Mixlib::ShellOut.new(
        '/usr/bin/stat -f%u /dev/console',
      ).run_command.stdout.strip
    end

    # Adds Windows value to Facebook's method
    # Windows requires node['organization'] to match domain
    def console_user
      # memoize the value so it isn't run multiple times per run
      @console_user ||=
        if self.macos?
          Etc.getpwuid(::File.stat('/dev/console').uid).name
        elsif self.linux?
          filtered_users = self.loginctl_users.select do |u|
            u['username'] != 'gdm' && u['uid'] >= 1000
          end
          if filtered_users.empty?
            Chef::Log.warn("Unable to determine user: #{e}")
            nil
          else
            filtered_users[0]['username']
          end
        elsif self.windows?
          wmic('computersystem get username').gsub("#{node['ogranization'].upcase}\\", "")
        end
    rescue StandardError => e
      Chef::Log.warn("Unable to determine user: #{e}")
      nil
    end

    def airwatch?
      installed?('com.air-watch.agent') ||
      installed?('com.air-watch.pkg.OSXAgent') ||
      installed?('*airwatch*') ||
      installed?('com.vmware.hub.mac')
    end

    def clean_hostname
      node['hostname'].strip.split('.')[0].strip
    end

    def docked_apps
      unless macos?
        Chef::Log.warn('node.docked_apps called on non-OS X!')
        return []
      end
      apps = []
      dock_plist = '/Library/Preferences/com.apple.dock.plist'
      plist = CFPropertyList::List.new(:file => ENV['HOME'] + dock_plist)
      data = CFPropertyList::native_types(plist.value)
      data['persistent-apps'].each do |a|
        apps.append(a['tile-data']['file-label'])
      end
      apps
    end

    def encrypted?
      if node.macos?
        status = Mixlib::ShellOut.new('/usr/bin/fdesetup isactive')
        status.run_command.stdout.strip.to_s == 'true'
      elsif node.windows?
        status = powershell_out(
          "Get-BitLockerVolume -MountPoint 'C:' | foreach { $_.VolumeStatus }"
        )
        status.stdout.chomp == 'FullyEncrypted'
      else
        raise "#{node['hostname']} called node.encrypted? on #{node['platform']}."
      end
    end

    def firewall_enabled?
      if node.macos?
        cmd = Mixlib::ShellOut.new(
          '/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate'
        ).run_command.stdout
        cmd.match?('enabled') ? true : false
      elsif node.windows?
        cmd = Mixlib::ShellOut.new(
          'sc query MpsSvc | FIND "STATE"'
        ).run_command.stdout
        cmd.match?('RUNNING') ? true : false
      else
        "#{node['hostname']} called node.firewall_enabled? on an unknown OS."
      end
    end

    def in_dock?(label)
      unless macos?
        Chef::Log.warn('node.in_dock? called on non-OS X!')
        return nil
      end
      docked_apps.include?(label)
    end

    def local_munki_manifest
      manifests = [serial, clean_hostname]
                  .map { |n| "/Library/Managed Installs/manifests/#{n}" }
                  .select { |f| File.exist? f }
                  .sort_by { |f| -File.mtime(f).to_i }
      if manifests.empty?
        nil
      else
        manifests[0]
      end
    end

    def munki_catalogs
      unless macos?
        Chef::Log.warn('node.munki_catalogs called on non-OS X!')
        return false
      end

      manifest_file = local_munki_manifest
      if manifest_file
        plist = Plist.parse_xml(manifest_file)
        plist['catalogs']
      else
        # Fallback case
        ['production']
      end
    end

    def munki_top_catalog
      unless macos?
        Chef::Log.warn('node.munki_top_catalog called on non-OS X!')
        return nil
      end
      munki_catalogs[0]
    end

    def on_corp_network?
      return nil unless node['corp_network_server_addr']

      begin
        Resolv::DNS.new.getaddress(node['corp_network_server_addr'])
      rescue Resolv::ResolvError, Errno::ENETDOWN, Errno::EADDRNOTAVAIL
        return false
      end
      true
    end

    # List printers from lpstat as hash { name => uri }
    def printers
      out = Mixlib::ShellOut.new('lpstat -p -v').run_command.stdout.split("\n")
                            .reject { |l| l.nil? || l.empty? }
      printer_lines = out.select { |l| l.include? 'device for' }
      result = {}
      printer_lines.each do |line|
        name = line.split(':')[0].gsub('device for', '').strip
        uri = line.split(':')[1...line.length].join(':').strip
        result[name] = uri
      end
      result
    end

    def wmic(command)
      unless windows?
        Chef::Log.warn('node.wmic called on non-Windows!')
        return nil
      end
      cmd_str = command.gsub('wmic', '').strip
      cmd = Mixlib::ShellOut.new("wmic #{cmd_str}")
      title = cmd_str.split[-1]
      cmd.run_command.stdout.lines.each do |l|
        l.strip!
        if l.downcase != title
          return l
        end
      end
    end

    def serial
      return node['serial'] if node['serial']

      if macos?
        serial = Mixlib::ShellOut.new(
          '/usr/sbin/ioreg -c IOPlatformExpertDevice |head -30' +
          '|grep IOPlatformSerialNumber | awk \'{print $4}\' | sed -e s/\"//g',
        ).run_command.stdout.chomp
      elsif windows?
        serial = Mixlib::ShellOut.new(
          'powershell.exe (Get-CimInstance -Class Win32_BIOS).SerialNumber'
        ).run_command.stdout.chomp
      end
      node.default['serial'] = serial
      serial
    end

    # Returns the full dsconfigad profile
    def dsconfigad_profile
      unless macos?
        Chef::Log.warn('node.dsconfigad called on non-OS X!')
        return nil
      end
      cmd = Mixlib::ShellOut.new('/usr/sbin/dsconfigad -xml -show')
      cmd.run_command
      cmd.error!
      Plist.parse_xml(cmd.stdout.strip)
    end

    def manufacturer
      if node.macos?
        'Apple'
      elsif node.windows?
        cmd = Mixlib::ShellOut.new('powershell.exe (Get-CimInstance -ClassName Win32_ComputerSystem).Manufacturer')
        cmd.run_command
        cmd.error!
        cmd.stdout.strip
      else
        nil
      end
    end

    def ❨╯°□°❩╯︵┻━┻
      puts "Calmer than you"
    end
  end
end
