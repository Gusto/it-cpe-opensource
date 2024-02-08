cpe_mdm_profiles Cookbook
=====================
This cookbook manages macOS configuration profiles.

Requirements
------------
* gusto_helpers

Attributes
----------
* node["cpe_mdm_profiles"]["middleware_config"]["key_data_bag_name"]
* node["cpe_mdm_profiles"]["middleware_config"]["middleware_name"]
* node["cpe_mdm_profiles"]["middleware_config"]["url_data_bag_name"]

This cookbook creates and assigns profiles as a client of an unpublished middleware.

## Recipes

* default

This recipe calls the `macos_mdm_profile` resource to install a list of profiles defined by node attributes in `cookbooks/cpe_mdm_profiles/attributes`. Profiles are not installed by default. Each profile hash includes a top level `enabled` key set to `false`. The default list of enabled profiles is defined in `cookbooks/cpe_init/`, where the `enabled` key is flipped to `true`.

To override whether a profile should be installed, set `enabled` to `true` or `false` within a `cpe_customizations` recipe.

```ruby
node.default["cpe_mdm_profiles"]["foocorp.Notifications"]["enabled"] = false
```
To override a profile attribute update a specific key within the corresponding payload.

```ruby
node.default["cpe_mdm_profiles"]["foocorp.SoftwareUpdate"]["payloads"][0]["AllowPreReleaseInstallation"] = true
```

## Resources

### macos_mdm_profile

This resource manages macOS MDM profile assignment via a middleware. It might be easier to think of this resource as crafting the necessary values of an HTTP request sent to the middleware, rather than a direct representation of a macOS MDM profile.

#### Actions

`:install` - Checks for the existence of a profile and installs it via a middleware.

`:remove` - Checks for the existence of a profile and removes it via a middleware.

#### Properties

**label** String

Profile name with prefix like foocorp.Firefox. Used with `:payload` property.


**payload** Hash

Hash containing the PayloadContent of a profile. Used with `:label` property.


**profile_name** String

The profile's name such as `foocorp.security.passcodes`. Must provide either profile_name or payload. If not specified, uses resource block's name. You _could_ also supply the profile's name including the MD5 hash such as `com.example:8d076d12346156e21a4a5b941a0d124c`, but that's not advisable as there's no guarantee the named profile will exist in your MDM.


**request_parameters** Hash

Hash containing parameters to pass along to the middleware at creation. Use with `:payload` property.


**scope** String

Define the PayloadScope of a profile, either User or System. Default is `System`.


#### Example usage

You can use this resource like most other Chef resources. For example, you can:

Remove profile by name property

```ruby
macos_mdm_profile "foocorp.security.passcodes" do
  action :remove
end
```

Remove profile by profile_name property
```ruby
macos_mdm_profile "Removing example profile" do
  profile_name "foocorp.security.passcodes"
  action :remove
end
```

Install profile with implicit/default action
```ruby
macos_mdm_profile "foocorp.security.passcodes"
```

Install profile by name property
```ruby
macos_mdm_profile "foocorp.security.passcodes" do
  action :install
end
```

Install profile by profile_name property
```ruby
macos_mdm_profile "Installing example profile" do
  profile_name "foocorp.security.passcodes"
  action :install
end
```

Most commonly, you'll pass a `:payload` and `:label` property so the middleware can create the profile for you. As you can see, the top-level key for each profile payload is used as the PayloadType. The keys beneath it are sorted and hashed to determine whether the profile is unique.

```ruby
profile = {
  "com.foo.app" => [
    "ApiKey" => data_bag_item("secrets", "app")["api_key"],
    "AutoUpdate" => true,
    "ServerURL" => "https://example.com",
    "Plugins" => [],
  ],
  "com.foo.bar" => [
    "PayloadDisplayName" => "Display name is optional, but will change hash",
    "AnotherValue" => true,
  ],
}

macos_mdm_profile "Installing example profile with payload" do
  payload profile
  label "foocorp.Foo"
  action :install
end
```

or inline:
```ruby
macos_mdm_profile "cpe_zoom profile" do
  payload({ "us.zoom.config" => [zoom_prefs] })
  label "foocorp.Zoom"
  action :install
end
```

You can also use the `request_parameters` property to pass along supported keys like `attribute_support` at creation time.

```ruby
profile = {
  "com.foo.app" => [
    "ServerURL" => "https://example.com",
    "EnrollmentUser" => "{{username}}",
  ],
}

macos_mdm_profile "Installing example profile with payload" do
  payload sal_profile
  label "foocorp.Foo"
  request_parameters ({"attribute_support" => true,})
  action :install
end
```

### zap_macos_mdm_profile

This removes macOS MDM profiles installed on a devices, but not defined as `macos_mdm_profile` resources during a current Chef run. Since this resource checks whether a `macos_mdm_profile` resource has already been executed, it's advisable to add this resource to the end of your Chef run, otherwise you may miss resources processed after your zap resource.

#### Properties

**label** (**REQUIRED**) String

Profile name with prefix like foocorp.Firefox.

#### Example usage

The resource will only remove profiles matching a regular expression, which is the `label` property followed by a `:` and any MD5 hash, like `foo.bar:5a6ba1f3dd4242249afd6b7846076836`.

```ruby
# Remove profiles starting with "foocorp.Firefox" not defined in the current Chef run
zap_macos_mdm_profile "Cleanup foocorp.Firefox profiles" do
  label "foocorp.Firefox"
end
```
