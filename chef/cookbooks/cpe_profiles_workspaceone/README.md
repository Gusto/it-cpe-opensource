cpe_profiles_workspaceone Cookbook
=====================
This is a cookbook that will manage all of the configuration profiles used with
Chef.

Requirements
------------
* macOS (10.9.0 and higher)
* cpe_workspaceone
* uber_helpers

Attributes
----------
* node['cpe_profiles_workspaceone']
* node['cpe_profiles_workspaceone']['prefix']

Lambda/WS1 profiles
-----

This cookbook should perhaps more accurately be called `cpe_profiles_ws1` as it manages
profiles via a Workspace One. The cookbook creates and assigns profiles as a client of this middleware: https://github.com/Gusto/it-terraform/tree/master/resources/lambda/src/ws1_profile_middleware in Lambda, behind API Gateway.

Additionally, via cpe_workspaceone's library, this cookbook scans assigned/installed profiles, and requests profile installs, with hubcli, a component of Workspace One's Intelligent Hub agent.

This cookbook follows the cpe_profiles cookbook broker method of installing macOS profiles. A profile installed by this cookbook will not be installed by any other means/cookbook. To use this cookbook with a profile, add it to the cookbook map - see Usage, below.

Usage
-----
Include this recipe and add any configuration profiles matching the format in the
example below.

**Note:** If you use this outside of Facebook, ensure that you override the
default value of `node['cpe_profiles_workspaceone']['prefix']`. If you do not do this, it
will assume a `PayloadIdentifier` prefix of `com.facebook.chef`.

**THIS MUST GO IN A RECIPE. DO NOT PUT THIS IN ATTRIBUTES, OR IT MAY CAUSE PAIN
AND SUFFERING FOR YOUR FLEET!**

To add a new config profile, in your recipe, add a key matching the
profile `PayloadIdentifier` with a value that contains the hash of the profile
to `node.default['cpe_profiles_workspaceone']`

For instance, add a hash to manage the loginwindow and use the default prefix:

```
lw_prefs = node['cpe_loginwindow'].reject { |\_k, v| v.nil? }
if lw_prefs.empty?
  Chef::Log.debug("#{cookbook_name}: No prefs found.")
  return
end

prefix = node['cpe_profiles_workspaceone']['prefix']
organization = node['organization'] ? node['organization'] : 'Facebook'
lw_profile = {
  'PayloadIdentifier' => "#{prefix}.loginwindow",
  'PayloadRemovalDisallowed' => true,
  'PayloadScope' => 'System',
  'PayloadType' => 'Configuration',
  'PayloadUUID' => 'e322a110-e760-40f7-a2ee-de8ee41f3227',
  'PayloadOrganization' => organization,
  'PayloadVersion' => 1,
  'PayloadDisplayName' => 'LoginWindow',
  'PayloadContent' => [],
}
unless lw_prefs.empty?
  lw_profile['PayloadContent'].push(
    'PayloadType' => 'com.apple.loginwindow',
    'PayloadVersion' => 1,
    'PayloadIdentifier' => "#{prefix}.loginwindow",
    'PayloadUUID' => '658d9a18-370e-4346-be63-3cb8a92cf71d',
    'PayloadEnabled' => true,
    'PayloadDisplayName' => 'LoginWindow',
  )
  lw_prefs.keys.each do |key|
    next if lw_prefs[key].nil?
    lw_profile['PayloadContent'][0][key] = lw_prefs[key]
  end
end
```

**If you already have profiles installed using an existing prefix, be sure to
convert all of them over to the new prefix. There will be pain and suffering if this
is not done.**

Or, if you want to customize the prefix and then add a profile, you would do:

```
# Override the default prefix value of 'com.facebook.chef'
node.default['cpe_profiles_workspaceone']['prefix'] = 'com.company.chef'
# Use the specified prefix to name the configuration profile
lw_prefs = node['cpe_loginwindow'].reject { |\_k, v| v.nil? }
if lw_prefs.empty?
  Chef::Log.debug("#{cookbook_name}: No prefs found.")
  return
end

prefix = node['cpe_profiles_workspaceone']['prefix']
organization = node['organization'] ? node['organization'] : 'Facebook'
lw_profile = {
  'PayloadIdentifier' => "#{prefix}.loginwindow",
  'PayloadRemovalDisallowed' => true,
  'PayloadScope' => 'System',
  'PayloadType' => 'Configuration',
  'PayloadUUID' => 'e322a110-e760-40f7-a2ee-de8ee41f3227',
  'PayloadOrganization' => organization,
  'PayloadVersion' => 1,
  'PayloadDisplayName' => 'LoginWindow',
  'PayloadContent' => [],
}
unless lw_prefs.empty?
  lw_profile['PayloadContent'].push(
    'PayloadType' => 'com.apple.loginwindow',
    'PayloadVersion' => 1,
    'PayloadIdentifier' => "#{prefix}.loginwindow",
    'PayloadUUID' => '658d9a18-370e-4346-be63-3cb8a92cf71d',
    'PayloadEnabled' => true,
    'PayloadDisplayName' => 'LoginWindow',
  )
  lw_prefs.keys.each do |key|
    next if lw_prefs[key].nil?
    lw_profile['PayloadContent'][0][key] = lw_prefs[key]
  end
end
```
