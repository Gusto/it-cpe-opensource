#
# Cookbook Name:: cpe_activedirectory
# Attributes:: default
#
#
#
# Gusto CPE Chef Cookbooks
# Copyright 2019 ZenPayroll, Inc., dba Gusto
#
# This product includes software developed by
# ZenPayroll, Inc., dba Gusto (https://www.gusto.com/).
#

# These attributes, if set to nil, _do not_ reflect the current value or value
# which will be applied. All nil values are discarded and existing value for
# that key will persist. It was likely applied by a DirectoryService.managed
# profile.

#
## Commented out keys are not currently supported
#

# Binding options
default['cpe_activedirectory'] = {
  'bind' => false,
  'bind_ldap_check_hostname' => nil, # Example: 'ldaps.ad.domain.tld'
  'bind_method' => 'profile_resource', # 'profile_resource' or 'execute_resource'
  'bind_options' => {
    'ADOrganizationalUnit' => nil, # Example: 'OU=computers,DC=ad,DC=domain,DC=tld'
    'ClientID' => nil, # Example: node.serial
    'HostName' => nil, # Example: 'ad.domain.tld'
    'Password' => nil,
    'UserName' => nil,
  },
  'configure' => false,
  # Because the profile keys and the dsconfigad flags differ, we need this
  # hardcoded map. We read the profile (`node.dsconfigad_profile`) to determine if a
  # value has changed, but we use the dsconfigad flag to set it.
  'flag_to_profile_map' => {
    'administrative' => {
      'alldomains' => 'Authentication from any domain',
      'groups' => 'Allowed admin groups',
      'namespace' => 'Namespace mode',
      'packetencrypt' => 'Packet encryption',
      'packetsign' => 'Packet signing',
      'passinterval' => 'Password change interval',
      'restrictDDNS' => 'Restrict Dynamic DNS updates',
    },
    'mappings' => {
      'authority' => 'Generate Kerberos authority',
    },
    'user_experience' => {
      'mobile' => 'Create mobile account at login',
      'localhome' => 'Force home to startup disk',
      'sharepoint' => 'Mount home as sharepoint',
      'protocol' => 'Network protocol',
      'mobileconfirm' => 'Require confirmation',
      'shell' => 'Shell',
      'useuncpath' => 'Use Windows UNC path for home',
    },
  }.freeze,
  'options' => {
    'administrative' => {
      'alldomains' => nil, # 'enable' or 'disable' allow authentication from any domain
      'groups' => nil, # List of groups that are granted Admin privileges on local workstation
      'namespace' => nil, # 'forest' or 'domain', where forest qualifies all usernames
      'nogroups' => nil, # Disable the use of groups for granting Admin privileges
      'nopreferred' => nil, # Do not use a preferred server for queries
      'packetencrypt' => nil, # 'disable', 'allow', 'require' or 'ssl' packet encryption
      'packetsign' => nil, # 'disable', 'allow', or 'require' packet signing
      'passinterval' => nil, # How often to change computer trust account password in days
      'preferred' => nil, # Fully-qualified domain name of preferred server to query
      'restrictDDNS' => nil, # List of interfaces to restrict DDNS to (en0, en1, etc.)
    },
    'mappings' => {
      # 'uid' => nil, # Name of attribute to be used for UNIX uid field
      # 'nouid' => nil, # Generate the UID from the Active Directory GUID
      # 'gid' => nil, # Name of attribute to be used for UNIX gid field
      # 'nogid' => nil, # Generate the GID from the Active Directory information
      # 'ggid' => nil, # Name of attribute to be used for UNIX group gid field
      # 'noggid' => nil, # Generate the group GID from the Active Directory GUID
      'authority' => nil, # Enable or disable generation of Kerberos authority
    },
    'user_experience' => {
      'mobile' => nil, # 'enable' or 'disable' mobile user accounts for offline use
      'mobileconfirm' => nil, # 'enable' or 'disable' warning for mobile account creation
      'localhome' => nil, # 'enable' or 'disable' force home directory to local drive
      'useuncpath' => nil, # 'enable' or 'disable' use Windows UNC for network home
      'protocol' => nil, # 'afp' or 'smb' change protocol used when mounting home
      'sharepoint' => nil, # 'enable' or 'disable' mount network home as a sharepoint.
      'shell' => nil, # 'none' for no shell or specify a default shell '/bin/bash'
    },
  },
  'unbind' => false,
  'unbind_method' => 'profile_resource', # 'profile_resource' or 'execute_resource'
  'what_if_execution' => false, # Print dsconfigad cmds that would be run, but do not execute
}
