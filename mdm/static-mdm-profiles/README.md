# static-mdm-profiles

This repo contains a pipeline for deploying static profiles to various MDMs.

The source code in this directory and subdirectories is licensed under the Apache 2.0 license.

# Adding new profiles

## Windows

Windows profiles in this repo are markdown files containing the profile payload and associated metadata. The pipeline to deploy profiles is not currently included in this repo.

## Apple devices

Profiles for Apple devices are defined as YAML files in either the *ios* or *macos* directory.

You can use this template as a starting point or reference an existing profile:

```yaml
name: "foocorp.Attributes.Device"
# description: "something" # Optional. Description presented to the end user. Pending feature request to add API support for this field https://suggestions.simplemdm.com/forums/204404-suggestions/suggestions/47084887-add-description-as-argument-for-creating-updating
mobileconfig: |
  <?xml version="1.0" encoding="UTF-8"?>
  <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
  <plist version="1.0">
  <dict>
  	<key>PayloadContent</key>
  	<array>
  		<dict>
  			<key>PayloadIdentifier</key>
  			<string>com.foocorp.custom.foo.E7B88101-7692-42CD-B647-345972A1793E</string>
  			<key>PayloadType</key>
  			<string>com.foocorp.mdm.attributes</string>
  			<key>PayloadUUID</key>
  			<string>E7B88101-7692-42CD-B647-345972A1793E</string>
  			<key>PayloadVersion</key>
  			<integer>1</integer>
  			<key>device_id</key>
  			<string>{{id}}</string>
  		</dict>
  	</array>
  	<key>PayloadType</key>
  	<string>Configuration</string>
  </dict>
  </plist>
user_scope: false # Optional. A boolean true or false. If false, deploy as a device profile instead of a user profile for macOS devices.
attribute_support: false # Optional. A boolean true or false. When enabled, SimpleMDM will process variables in the uploaded profile.
escape_attributes: false # Optional. A boolean true or false. When enabled, SimpleMDM escape the values of the custom variables in the uploaded profile.
reinstall_after_os_update: false # Optional. A boolean true or false. When enabled, SimpleMDM will re-install the profile automatically after macOS software updates are detected.
```

Make sure you're generating a unique PayloadUUID with `uuidgen` or a similar tool.

### Secrets

Secrets can be injected by adding them as a Github Actions secrets and setting them as environment variables on the deploy workflow.

For example, embedding a secret in the mobileconfig key of a YAML definition:
```xml
...
  <key>Challenge</key>
  <string>$PROFILE_SECRET_WIFI_PASSPHRASE</string>
...
```

And then adding the secret to the deployment workflow:

```yaml
        env:
          SIMPLEMDM_API_KEY: ${{ secrets.SIMPLEMDM_API_KEY }}
          PROFILE_SECRET_OKTA_CERT_CHALLENGE: ${{ secrets.PROFILE_SECRET_WIFI_PASSPHRASE }}
```

# Deploying

Upon changes to the `main` branch, a workflow runs to update SimpleMDM profiles via the [API](https://api.simplemdm.com/#custom-configuration-profiles).