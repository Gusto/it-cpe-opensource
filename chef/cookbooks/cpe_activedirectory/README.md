cpe_activedirectory Cookbook
=========================
Uses dsconfigad to apply options on top of any existing com.apple.DirectoryService.managed
profile.


Requirements
------------
macOS


Attributes
----------
See attributes/default.rb for details. Stiketrhough'd attributes are not
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


Dependencies
----------

* An AD-bound Macbook (heaven help you).
* cpe_utils' dsconfigad_profile method
