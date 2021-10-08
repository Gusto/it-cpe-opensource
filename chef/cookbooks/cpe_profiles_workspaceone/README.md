cpe_profiles_workspaceone Cookbook
=====================
This cookbook works with cpe_profiles, cpe_workspaceone and a python middleware to manage profiles on a macOS device via VMware Workspace ONE UEM.

Requirements
------------
* macOS (10.9.0 and higher)
* cpe_workspaceone
* uber_helpers
* hubcli/Intelligent Hub installed for use by cpe_workspaceone
* the device must be enrolled with a WS1 instance, naturally
* Somewhere to host the middleware script triggered by an HTTP request, such as AWS Lambda and API gateway, Google Cloud Functions, or Apache OpenWhisk.

Attributes
----------
* node['cpe_profiles_workspaceone']
* node['cpe_profiles_workspaceone']['prefix']
* node['cpe_profiles_workspaceone']['lambda_config']['url']
* node['cpe_profiles_workspaceone']['lambda_config']['key']

Cookbook Design
-----
This cookbook is a client of this [middleware](https://github.com/Gusto/it-cpe-opensource/tree/master/chef/mdm_middleware), which is designed to be hosted in AWS Lambda. The cookbook is agnostic: the middleware can be reimplemented in your preferred language or environment.

The cookbook also utilizes `hubcli`, VMware's CLI utility for interacting with a Workspace ONE instance. `hubcli` is a compontent of the Intelligent Hub agent, which must be installed. Additionally, `cpe_workspaceone` and `uber_helpers` provide chef's interface with `hubcli`.

The cookbook expects `cpe_profiles` to populate a list of profiles to manage. Profiles are defined in their cookbooks, passed to `cpe_profiles`, passed to `cpe_profiles_workspaceone`, and, if an install is pending, passed to `cpe_workspaceone`. To manage a profile with this cookbook, add it to cpe_profiles's cookbook map - see Usage for examples.

Profiles are named with a hash of their sorted payload contents (specifically: `<prefix>.<preference domain>:<hash>`). By only comparing the payload hash, the middleware and the cookbook never need to inspect the profile contents to determine whether it needs to be created server-side. If a profile is already assigned or already installed, and `hubcli` accurately reports this state, no call to the middleware is made.

You will need to create an assignment group scoped to the devices you wish to manage with this cookbook, so profiles can be made available as optional installs, allowing them to be installed via `hubcli` and uninstalled via the middleware. As of early 2021, `hubcli` can only install profiles, so profile removal is handled by the middleware.

Currently the cookbook assumes device/system profiles. Using this middleware for user profiles will require modifying the cookbook and middleware.

Middleware Design
-----

The middleware was written to be deployed with AWS Lambda and API gateway. Because the lambda environment no longer has the Python `requests` library, you'll need to configure a lambda layer containing a recent version of `requests` for Python 3.

Your API endpoint should be protected with some sort of authentication, such as an API key, to prevent the creation of arbitrary MDM profiles by external parties. This can be set with the `['lambda_config']['key']` attribute.

We recommend using the middleware with a dedicated WS1 admin account with a very limited permission set. You'll want to keep `AIRWATCH_PASSWORD` and `AIRWATCH_KEY` in a secrets management system like AWS Secrets Manager or [HashiCorp Vault](https://github.com/hashicorp/vault) instead of hardcoding them in the middleware script or storing them as environment variables.

Environment variables to set:

`AIRWATCH_USER` - a dedicated admin user for the middleware
`AIRWATCH_DOMAIN` - the FQDN for your Workspace ONE instance `ab123.awmdm.com`
`MANAGEDLOCATIONGROUPID` - Contact VMware support if you don't know your Group ID  
`SMARTGROUPID` - the assignment group for devices managed by this cookbook  

Example API request:

```
{
  "name": "acme.screensaver:2a82af3046179700b07b62f96ceaee5c",
  "hash": "2a82af3046179700b07b62f96ceaee5c",
  "action": "install",
  "profile": {
    "PayloadIdentifier": "com.acme.chef.workspaceone.lambda.screensaver",
    "PayloadRemovalDisallowed": "true",
    "PayloadScope": "System",
    "PayloadType": "Configuration",
    "PayloadUUID": "01EAE433-3824-4991-A358-C276AF3B995D",
    "PayloadOrganization": "acme",
    "PayloadVersion": 1,
    "PayloadDisplayName": "Screensaver",
    "PayloadContent": [
      {
        "PayloadType": "com.apple.screensaver",
        "PayloadVersion": 1,
        "PayloadIdentifier": "com.acme.chef.workspaceone.lambda.screensaver",
        "PayloadUUID": "3CEDF590-B2C6-4283-84D9-027E30826B8B",
        "PayloadEnabled": "true",
        "PayloadDisplayName": "Screensaver",
        "SomeValue": "false"
      }
    ]
  }
}
```

Usage
-----

Use at your own risk and test carefully. Start with just one profile managed via cpe_profiles_workspaceone.

Define a cookbook_map or set the default_cookbook. For instance:

```
node.default['cpe_profiles']['default_cookbook'] = 'cpe_profiles_workspaceone'
```

```
%w(
    ublock
    browsers.chrome
    screensaver
    prefpanes
  ).each do |profile_domain|
    node.default['cpe_profiles']['cookbook_map']["#{node['cpe_profiles']['prefix']}.#{profile_domain}"] = 'cpe_profiles_workspaceone'
  end
```

As with `cpe_profiles_local`, you must define a prefix - profiles installed by Workspace ONE but not containing this prefix will be ignored. You can continue to directly use cpe_workspaceone to install otherwise unmanaged-by-chef profiles.

```
node['cpe_profiles_workspaceone']['prefix'] = 'gusto'
```

If you use `cpe_workspaceone` to install the agent, your profiles will not install on the first attempt, since `cpe_profiles_workspaceone` will not be able to read profile assignment/install state until the agent is installed. We solved this by breaking out the install to a separate recipe that runs before cpe_profiles_workspaceone. For example, to manage the screensaver profile, your run list should have this order:

```
cpe_workspaceone::install_agent,
cpe_screensaver,
cpe_profiles,
cpe_profiles_workspaceone,
cpe_workspaceone::manage_mdm_profiles
```

Todo
-----
* scaling: when does this fall over?

  API Gateway (or your preferred platform) can be scaled to handle a huge number of requests per second, or rate limited depending on your preferences. The likely bottleneck is the Workspace ONE API, which we have not stress tested by running this cookbook on >3,000 endpoints.

* use murmurhash or another short hash suitable for lookups across ~10,000 items. Will make profiles look slightly nicer. Algorithm must be inlined if not available in ruby standard library.
* perhaps implement a standalone install/uninstall provider for osx_profile, for use outside the cpe_* attributes pattern.
* add support for profile contexts (ie, user profiles)
