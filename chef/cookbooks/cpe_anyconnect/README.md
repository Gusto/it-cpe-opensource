# cpe_anyconnect

Manages the XML profiles for "Cisco AnyConnect Secure Mobility Client.app"

# Usage

The `cpe_anyconnect` resource serializes `node['cpe_anyconnect']['server_preferences']` into a (hopefully valid) XML profile defining 1 or more VPN endpoints.

For basic usage, define the server list. An example:

```ruby
"ServerList"=>
 [{"HostEntry"=>
    [{"HostName" => [{'content' => 'London VPN Endpoint'}],
      "HostAddress" => [{'content' => 'london.vpn.corp.com'}],
      }]}]}
```

`node['cpe_anyconnect']['global_preferences']` becomes the global profile.

The attributes arrays defining these XML profiles has complicated nesting. This data structure is serialization format for [XmlSimple](https://www.rubydoc.info/gems/xml-simple/1.1.2/XmlSimple). Keys will be discarded if their value, even if a deep nesting, amounts to `nil` (see `def compact`).

 With so many keys available, it's easy to define a broken profile. Generated profiles are validated against the XSD schema included with a Cisco AnyConnect install (`/opt/cisco/anyconnect/profile/AnyConnectProfile.xsd`).

 The validation result is output to the log with the tag "AnyConnectProfile Validation." If `node['cpe_anyconnect']['validation']['strict']` is set, an exception will be raised. If `['write_anyways']` is set it will write anyways so you may inspect the invalid profile.

Note it is very possible to break the client with a valid profile. [Cisco's documentation on AnyConnect preferences](https://www.cisco.com/c/en/us/td/docs/security/vpn_client/anyconnect/anyconnect40/administration/guide/b_AnyConnect_Administrator_Guide_4-0/anyconnect-profile-editor.html#ID-1430-0000006c).

# Shim Usage

Included is a resource to write a shim script. (Credit for script to https://github.com/szarya.)

"A metaprogrammed shim for non-interactively (or less-interactively) managing your Cisco AnyConnect VPN Client connection."

This is mostly useful if you've configured AnyConnect to use a pre-shared passcode with Duo ("ASA SSL VPN using LDAPS"): https://duo.com/docs/cisco. In all other cases, you're better off disabling it. (Though it would probably support any other flow that does not involve an interactive prompt from the client, or one in which the prompt accepts non-secret pre-shared input.)

The script could be adapted to support other workflows and simplify your user's lives - PRs welcome!

# Some Important Keys

You may define multiple endpoints:

```ruby
"ServerList"=>
 [{"HostEntry"=>
    [{"HostName" => [{'content' => 'Endpoint 0'}],
      "HostAddress" => [{'content' => 'e0.corp.com'}],
      }]},
  {"HostEntry"=>
    [{"HostName" => [{'content' => 'Endpoint 1'}],
      "HostAddress" => [{'content' => 'e1.corp.com'}]}]}]}
```

You may use the CPE customization API pattern to add additional endpoints:

```ruby
node.default['cpe_anyconnect']['server_preferences']['ServerList'] += [{"HostEntry"=>
 [{"HostName" => [{'content' => 'Endpoint 3'}],
   "HostAddress" => [{'content' => 'e0.corp.com'}],
 }]}]
```

 If you use certificate (radius) auth, you may specify the keychain:

 ```ruby
 {"CertificateStore" => ["All"],
 "CertificateStoreMac" => ["Login"],
 "CertificateStoreOverride" => [false],}
 ```

# To Do

* Support per-server preferences, which is entirely possible: multiple profiles can be written, one for each server
* **Turn the validation function into a proper spec**
* Refactor profile writing loop/methods to be DRY
* Support complex 2FA configuration
* Complicated keys and nesting call for better documentation
 * Issues very welcome
* Support for installing and updating the client pkg
* Abstract "ServerList" to be more operator-friendly?
