# macos_resources

## Resources

### macos_pkg

This resource installs a macOS `.pkg` file, optionally downloading it from a remote source by calling `remote_file`. A `package_id` property must be provided for idempotency. Either a `file` or `source` property is required. The `version` property is only necessary when updating existing packages.

#### Properties

**checksum** String

The SHA-256 checksum of the package file to download.


**file** String

The absolute path to the package file on the local system.


**headers** Hash

Allows custom HTTP headers (like cookies) to be set on the `remote_file` resource.


**package_id** (**REQUIRED**) String

The package ID registered with `pkgutil` when a `pkg` or `mpkg` is installed.

**source** String

The remote URL used to download the package file, if specified.


**target** String, default: "/"

The device to install the package on.

**version** String

The version of the package ID defined in `package_id`, optional unless updating an existing package. The package will only be installed if the specified version is higher than the installed version and doesn't support downgrading. Be sure to test for non-semantic version strings, like 1.5.2b2, 2.2beta29, 1.13rc3, since they may not evaluate as expected.

#### Example usage

```ruby
macos_pkg "osquery installer" do
  checksum "196c84e329be3459168ac184c9e49e6d40be1c08a0354cb178ec91123734c7ed"
  package_id "io.osquery.agent"
  source "https://github.com/osquery/osquery/releases/download/5.8.2/osquery-5.8.2.pkg"
  version "5.8.2"
end
```

### kcpassword

Writes kcpassword file to `/etc/kcpassword`.

#### Actions

`:create` - XORs password and manages file.

`:delete` - Deletes managed file.

#### Properties

**password** String

Password to XOR, ideally using an encrypted data bag item. Required when using the `:create` action.

_Examples_


Creating
```ruby
kcpassword "Manage kcpasswd file" do
  password data_bag_item("cookbook_secrets", "kcpassword")["present"]
end
```

Removing
```ruby
kcpassword "Delete kcpasswd file" do
  action :delete
end
```