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
# ZenPayroll, Inc., dba Gusto (http://www.gusto.com/).
#

# These attributes, if set to nil, _do not_ reflect the current value or value
# which will be applied. All nil values are discarded and existing value for
# that key will persist. It was likely applied by a DirectoryService.managed
# profile.

#
## Commented out keys are not currently supported
#

# 'enable' or 'disable' mobile user accounts for offline use
default['cpe_activedirectory']['options']['user_experience']['mobile'] = nil
# 'enable' or 'disable' warning for mobile account creation
default['cpe_activedirectory']['options']['user_experience']['mobileconfirm'] =
  nil
# 'enable' or 'disable' force home directory to local drive
default['cpe_activedirectory']['options']['user_experience']['localhome'] = nil
# 'enable' or 'disable' use Windows UNC for network home
default['cpe_activedirectory']['options']['user_experience']['useuncpath'] = nil
# 'afp' or 'smb' change protocol used when mounting home
default['cpe_activedirectory']['options']['user_experience']['protocol'] = nil
# 'enable' or 'disable' mount network home as a sharepoint.
default['cpe_activedirectory']['options']['user_experience']['sharepoint'] =
  nil
# 'none' for no shell or specify a default shell '/bin/bash'
default['cpe_activedirectory']['options']['user_experience']['shell'] = nil

# Name of attribute to be used for UNIX uid field
# default['cpe_activedirectory']['options']['mappings']['uid'] = nil
# Generate the UID from the Active Directory GUID
# default['cpe_activedirectory']['options']['mappings']['nouid'] = nil
# Name of attribute to be used for UNIX gid field
# default['cpe_activedirectory']['options']['mappings']['gid'] = nil
# Generate the GID from the Active Directory information
# default['cpe_activedirectory']['options']['mappings']['nogid'] = nil
# Name of attribute to be used for UNIX group gid field
# default['cpe_activedirectory']['options']['mappings']['ggid'] = nil
# Generate the group GID from the Active Directory GUID
# default['cpe_activedirectory']['options']['mappings']['noggid'] = nil
# Enable or disable generation of Kerberos authority
default['cpe_activedirectory']['options']['mappings']['authority'] = nil

# Fully-qualified domain name of preferred server to query
default['cpe_activedirectory']['options']['administrative']['preferred'] = nil
# Do not use a preferred server for queries
default['cpe_activedirectory']['options']['administrative']['nopreferred'] = nil
# List of groups that are granted Admin privileges on local workstation
default['cpe_activedirectory']['options']['administrative']['groups'] = nil
# Disable the use of groups for granting Admin privileges
default['cpe_activedirectory']['options']['administrative']['nogroups'] = nil
# 'enable' or 'disable' allow authentication from any domain
default['cpe_activedirectory']['options']['administrative']['alldomains'] = nil
# 'disable', 'allow', or 'require' packet signing
default['cpe_activedirectory']['options']['administrative']['packetsign'] = nil
# 'disable', 'allow', 'require' or 'ssl' packet encryption
default['cpe_activedirectory']['options']['administrative']['packetencrypt'] =
  nil
# 'forest' or 'domain', where forest qualifies all usernames
default['cpe_activedirectory']['options']['administrative']['namespace'] = nil
# How often to change computer trust account password in days
default['cpe_activedirectory']['options']['administrative']['passinterval'] =
  nil
# List of interfaces to restrict DDNS to (en0, en1, etc.)
# This is intentially incorrect because we do not want any interface to set DDNS
default['cpe_activedirectory']['options']['administrative']['restrictDDNS'] = nil

default['cpe_activedirectory']['configure'] = false
# Print dsconfigad cmds that would be run, but do not execute
default['cpe_activedirectory']['what_if_execution'] = false

# Because the profile keys and the dsconfigad flags differ, we need this
# hardcoded map. We read the profile (`node.dsconfigad_profile`) to determine if a
# value has changed, but we use the dsconfigad flag to set it.
# Mooph.
default['cpe_activedirectory']['flag_to_profile_map'] = {
  'administrative' => {
    'namespace' => 'Namespace mode',
    'packetencrypt' => 'Packet encryption',
    'packetsign' => 'Packet signing',
    'passinterval' => 'Password change interval',
    'restrictDDNS' => 'Restrict Dynamic DNS updates'
  },
  'mappings' => {
    'authority' => 'Generate Kerberos authority'
  },
  'user_experience' => {
    'mobile' => 'Create mobile account at login',
    'localhome' => 'Force home to startup disk',
    'sharepoint' => 'Mount home as sharepoint',
    'protocol' => 'Network protocol',
    'mobileconfirm' => 'Require confirmation',
    'shell' => 'Shell',
    'useuncpath' => 'Use Windows UNC path for home'
  }
}.freeze
