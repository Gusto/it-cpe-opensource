cpe_notifications Cookbook
=====================
Uses the `cpe_profiles` API to write a com.apple.notifications profile.


This API is deprecated, since the `profiles` command is deprecated.

Requirements
------------
* macOS

Attributes
----------
* node['cpe_notifications']['configure']

* node['cpe_notifications']['applications'][<bundle id>]

Usage
-----
You may configure these keys:

```ruby
{
  'AlertType' => 1,
  'BadgesEnabled' => true,
  'CriticalAlertsEnabled' => true,
  'NotificationsEnabled' => true,
  'ShowInLockScreen' => true,
  'ShowInNotificationCenter' => true,
  'SoundsEnabled' => true
}
```
You must use the application's bundle ID, generally found in an Info.plist, to configure its notificition setting.

The example profile, below, contains the bundle IDs for several common applications with all alerts enabled.


Example Profile payload(s)
-----

copy/paste to your delight

```ruby
node.default['cpe_notifications'] = {
  'configure' => !node.os_less_than?('10.15'),
  'applications' => {
    'org.mozilla.firefox' =>
      {
        'AlertType' => 1,
        'BadgesEnabled' => true,
        'CriticalAlertsEnabled' => true,
        'NotificationsEnabled' => true,
        'ShowInLockScreen' => true,
        'ShowInNotificationCenter' => true,
        'SoundsEnabled' => true
      },
    'com.github.sheagcraig.yo' =>
      {
        'AlertType' => 1,
        'BadgesEnabled' => true,
        'CriticalAlertsEnabled' => true,
        'NotificationsEnabled' => true,
        'ShowInLockScreen' => true,
        'ShowInNotificationCenter' => true,
        'SoundsEnabled' => true
      },
    'com.microsoft.autoupdate.fba' =>
      {
        'AlertType' => 1,
        'BadgesEnabled' => true,
        'CriticalAlertsEnabled' => true,
        'NotificationsEnabled' => true,
        'ShowInLockScreen' => true,
        'ShowInNotificationCenter' => true,
        'SoundsEnabled' => true
      },
    'com.googlecode.munki.ManagedSoftwareCenter' =>
      {
        'AlertType' => 1,
        'BadgesEnabled' => true,
        'CriticalAlertsEnabled' => true,
        'NotificationsEnabled' => true,
        'ShowInLockScreen' => true,
        'ShowInNotificationCenter' => true,
        'SoundsEnabled' => true
      },
    'com.airwatch.mac.agent' =>
      {
        'AlertType' => 1,
        'BadgesEnabled' => true,
        'CriticalAlertsEnabled' => true,
        'NotificationsEnabled' => true,
        'ShowInLockScreen' => true,
        'ShowInNotificationCenter' => true,
        'SoundsEnabled' => true
      },
    'com.vmware.hub.mac' =>
      {
        'AlertType' => 1,
        'BadgesEnabled' => true,
        'CriticalAlertsEnabled' => true,
        'NotificationsEnabled' => true,
        'ShowInLockScreen' => true,
        'ShowInNotificationCenter' => true,
        'SoundsEnabled' => true
      },
    'com.agilebits.onepassword7' =>
      {
        'AlertType' => 1,
        'BadgesEnabled' => true,
        'CriticalAlertsEnabled' => true,
        'NotificationsEnabled' => true,
        'ShowInLockScreen' => true,
        'ShowInNotificationCenter' => true,
        'SoundsEnabled' => true
      },
    'com.google.Chrome' =>
      {
        'AlertType' => 1,
        'BadgesEnabled' => true,
        'CriticalAlertsEnabled' => true,
        'NotificationsEnabled' => true,
        'ShowInLockScreen' => true,
        'ShowInNotificationCenter' => true,
        'SoundsEnabled' => true
      },
    'com.google.chrome.framework.alertnotificationservice' =>
      {
        'AlertType' => 1,
        'BadgesEnabled' => true,
        'CriticalAlertsEnabled' => true,
        'NotificationsEnabled' => true,
        'ShowInLockScreen' => true,
        'ShowInNotificationCenter' => true,
        'SoundsEnabled' => true
      },
    'com.tinyspeck.slackmacgap' =>
      {
        'AlertType' => 1,
        'BadgesEnabled' => true,
        'CriticalAlertsEnabled' => true,
        'NotificationsEnabled' => true,
        'ShowInLockScreen' => true,
        'ShowInNotificationCenter' => true,
        'SoundsEnabled' => true
      }
  }
}
```
