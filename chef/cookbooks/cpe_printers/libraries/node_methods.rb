# SPDX-FileCopyrightText: Gusto, Inc.
#
# SPDX-License-Identifier: Apache-2.0

# Cookbook:: cpe_printers
# Library:: node_methods

require "resolv"

class Chef
  class Node
    def resolvable?(domain)
      begin
        Resolv::DNS.open do |dns|
          dns.timeouts = 1
          dns.getaddress(domain)
        end
        return true
      rescue Resolv::ResolvError, Errno::ENETDOWN, Errno::EADDRNOTAVAIL, Errno::ECONNREFUSED, Errno::EHOSTUNREACH
        return false
      end
    end

    def domain_to_ip(domain)
      begin
        Resolv::DNS.open do |dns|
          dns.timeouts = 1
          return dns.getaddress(domain).to_s
        end
      rescue Resolv::ResolvError, Errno::ENETDOWN, Errno::EADDRNOTAVAIL, Errno::ECONNREFUSED, Errno::EHOSTUNREACH
        return
      end
    end
  end
end
