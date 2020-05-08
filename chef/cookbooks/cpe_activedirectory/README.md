cpe_activedirectory Cookbook
=========================
- Binds to active directory
- Uses `dsconfigad` to apply options on top of any previously bound machine


Requirements
------------
macOS

Notes
------------
Attempting to bind with the profile_resource and simultaneously run the
configure resource will result in the profile failing. The cookbook
will warn and return if you attempt to do this configuration.

Attributes
----------
See attributes/default.rb for details. Attributes with strikethroughs are not
supported but could be in future.

* node['cpe_activedirectory']['what_if_execution']
* node['cpe_activedirectory']['flag_to_profile_map']

Advanced Options - User Experience:
* node['cpe_activedirectory']['options']['user_experience']['mobile']
* node['cpe_activedirectory']['options']['user_experience]['mobileconfirm']
* node['cpe_activedirectory']['options']['user_experience]['localhome']
* node['cpe_activedirectory']['options']['user_experience]['useuncpath']
* node['cpe_activedirectory']['options']['user_experience]['protocol']
* node['cpe_activedirectory']['options']['user_experience]['sharepoint']
* node['cpe_activedirectory']['options']['user_experience]['shell']

Advanced Options - Mappings:
* ~~node['cpe_activedirectory']['options']['mappings']['uid']~~
* ~~node['cpe_activedirectory']['options']['mappings']['nouid']~~
* ~~node['cpe_activedirectory']['options']['mappings']['gid']~~
* ~~node['cpe_activedirectory']['options']['mappings']['nogid']~~
* ~~node['cpe_activedirectory']['options']['mappings']['ggid']~~
* ~~node['cpe_activedirectory']['options']['mappings']['noggid']~~
* node['cpe_activedirectory']['options']['mappings']['authority']

Advanced Options - Administrative:
* node['cpe_activedirectory']['options']['administrative']['preferred']
* node['cpe_activedirectory']['options']['administrative']['nopreferred']
* node['cpe_activedirectory']['options']['administrative']['groups']
* node['cpe_activedirectory']['options']['administrative']['nogroups']
* node['cpe_activedirectory']['options']['administrative']['alldomains']
* node['cpe_activedirectory']['options']['administrative']['packetsign']
* node['cpe_activedirectory']['options']['administrative']['packetencrypt']
* node['cpe_activedirectory']['options']['administrative']['namespace']
* node['cpe_activedirectory']['options']['administrative']['passinterval']
* node['cpe_activedirectory']['options']['administrative']['restrictDDNS']

Binding Options:
* node['cpe_activedirectory']['bind']
* node['cpe_activedirectory']['bind_ldap_check_hostname']
* node['cpe_activedirectory']['bind_ldap_check_port']
* node['cpe_activedirectory']['bind_ldap_check_port_timeout']
* node['cpe_activedirectory']['bind_method'] (defaults to profile_resource)
* node['cpe_activedirectory']['bind_options']['UserName']
* node['cpe_activedirectory']['bind_options']['Password']
* node['cpe_activedirectory']['bind_options']['ClientID']
* node['cpe_activedirectory']['bind_options']['HostName']
* node['cpe_activedirectory']['bind_options']['ADOrganizationalUnit']
* node['cpe_activedirectory']['remediate']
* node['cpe_activedirectory']['unbind']
* node['cpe_activedirectory']['unbind_method'] (defaults to profile_resource)

Usage
-----
The profile will manage the `com.apple.DirectoryService.managed` preference domain.

The profile's organization key defaults to `Gusto` unless `node['organization']` is
configured in your company's custom init recipe. The profile will also use
whichever prefix is set in `node['cpe_profiles']['prefix']`, which defaults to `com.facebook.chef`

The profile delivers a payload of all keys in `node['cpe_activedirectory']['bind_options']`
that are non-nil values.  All provided keys are nil by default, so that no profile is
installed without overriding. You can add additional functionality not documented by
passing any Apple profile key. For an authoritative list of keys,
please see [Apple's developer documentation](https://developer.apple.com/documentation/devicemanagement/directoryservice?language=objc).


Example:

Only using the profile to bind

```
node.default['cpe_activedirectory']['bind'] = true
node.default['cpe_activedirectory']['bind_ldap_check_hostname'] = 'ldaps.ad.domain.tld'
node.default['cpe_activedirectory']['bind_options']['UserName'] = 'service_account'
node.default['cpe_activedirectory']['bind_options']['Password'] = 'super_secret_password'
node.default['cpe_activedirectory']['bind_options']['ClientID'] = node.serial
node.default['cpe_activedirectory']['bind_options']['HostName'] = 'ad.domain.tld'
node.default['cpe_activedirectory']['bind_options']['ADOrganizationalUnit'] =
  'OU=computers,DC=ad,DC=domain,DC=tld'
```

Maintaining a configuration after binding

```
node.default['cpe_activedirectory']['configure'] = true
node.default['cpe_activedirectory']['options']['user_experience']['mobile'] = false
node.default['cpe_activedirectory']['options']['user_experience']['localhome'] = true
node.default['cpe_activedirectory']['options']['user_experience']['shell'] = '/bin/zsh'
node.default['cpe_activedirectory']['options']['user_experience']['protocol'] = 'smb'
node.default['cpe_activedirectory']['options']['administrative']['groups'] = ['domain admins']
node.default['cpe_activedirectory']['options']['administrative']['alldomains'] = false
node.default['cpe_activedirectory']['options']['administrative']['namespace'] = 'forest'
node.default['cpe_activedirectory']['options']['administrative']['packetsign'] = 'allow'
node.default['cpe_activedirectory']['options']['administrative']['packetencrypt'] = 'allow'
node.default['cpe_activedirectory']['options']['administrative']['passinterval'] = 30
```

Auto remediation

```
node.default['cpe_activedirectory']['bind'] = true
node.default['cpe_activedirectory']['remediate'] = true
```

Auto remediation (alternative)

```
node.default['cpe_activedirectory']['bind'] = true
node.default['cpe_activedirectory']['unbind'] = true
```

Dependencies
----------
* [uber_helpers cookbook](https://github.com/uber/cpe-chef-cookbooks)
* [cpe_utils cookbook](https://github.com/facebook/IT-CPE)
