cpe_yo Cookbook
========================
A chef interface for sending and scheduling [sheacraig's Yo alerts](https://github.com/sheagcraig/yo).

Known Issues/Important Caveats
-----

This cookbook relies on a custom fork of cpe_launchd to properly enable a launchd `asuser`. It also relies on a node function, `node.console_uid`. You may find both these among the cookbooks included in this repo.

Attributes
-----
* node['cpe_yo']['yo_binary']
* node['cpe_yo']['configure']
* node['cpe_yo']['launchd'] - Customizations to the launchd responsible for scheduled alerts. Do not override `program_arguments`, or other environment-dependent launchd keys, without testing.
* node['cpe_yo']['user_alert_blacklist'] - We never configure the alert schedule - never send any alerts - to these users

Usage
-----

Use the cpe_yo resource actions to send and schedule alerts.

### Actions

#### :send

The default. Immediately send an alert (ie, during a Chef run).

Examples:

```ruby
cpe_yo "Alert Title" do
  action :send
  subtitle "A call to action!"
end
```

```ruby
cpe_zoom "Configure Zoom" do
  action :configure
  notifies :send, "cpe_yo[Zoom has been configured!]", :immediately
end
```

#### :schedule

Schedule an alert to be run once in the future. You must set a `conditional_script` or `at` property!

A `conditional_script` is a script in any scripting language (given a working shebang! I recommend `!#/usr/bin/python` or `#!/bin/sh`.) If this script exits 0, your alert will fire.

An `at` property is a `Time` or `DateTime` object. You alert will fire once this time is past, given any conditional_scripts exit 0.

Alerts will fire only once unless the yo schedule is reset by manually by removing `/usr/local/lib/yo/.receipts`.

Scheduled alerts are idempotent. That is, only the alerts scheduled in the latest chef-client run will be queued for scheduling. You can remove an item from the schedule by deleting the call to cpe_yo that created it.

[Be sure to read about the `at` property](#at).

Examples:

```ruby
require 'date'

cpe_yo 'Happy Christmas!' do
  action :schedule
  at DateTime.parse("25 Dec 2019 09:00:00-07:00")
end
```

#### :trigger_scheduled

Immediately triggers yo_launchd.py

#### :configure

Configures the yo schedule, the yo scheduler launchd, and files required by alerts.
As with cpe_profiles, one should call these at the end of your run_list - after all
alerts have been scheduled.

#### :reset

Use with care. Calling this will immediately (*before convergence of run_list*) remove Yo content images, icons, delivery sounds, and the schedule.


Resource Properties
-----

* `at`: [A DateTime](#at)

* `conditional_script`: A script in any scripting language (given a working shebang! I recommend `!#/usr/bin/python` or `#!/bin/sh`.) If this script exits 0, your alert will fire. Meaningless on all actions save `:schedule`.

#### Yo binary properties

Save where noted in bold, these properties are passed unedited to the Yo binary
when an alert is sent (whether via `:schedule` or `:send`).

* `title`: Title for notification. Required. The name property.

* `subtitle`:
  Subtitle for notification.

* `info`:
  Informative text.

* `action_btn`:
  Include an action button, with the button label text supplied to this argument.

* `action_path`:
  Application to open if user selects the action button. Provide the full path as the argument. This option only does something if action_btn is also specified.

* `bash_action`:
  Bash script to run. Be sure to properly escape all reserved characters. This option only does something if action_btn is also specified. Defaults to opening nothing. **This script should be included in `files/bash_actions/`.**

* `other_btn`:
  Alternate label for cancel button text.

* `icon`:
  Complete path to an alternate icon to use for the notification. **This file should be included in `files/icons/`.**

* `content_image`:
  Path to an image to use for the notification's :contentImage property. **This file should be included in `files/content_images/`.**

* `delivery_sound`:
  The name of the sound to play when delivering notifications. The name should either be:

  **The name of a file in '/Library/Sounds' or '~/Library/Sounds' *sans full path*. Otherwise, the name, with extension, of a file added to `files/delivery_sounds` - cpe_yo will take care of moving it to /Library/Sounds and passing the correct value to Yo.**

  **The extension, and the file format, must always be .aiff. You'll find it easy to convert other formats to .aff**

* `ignores_do_not_disturb`:
  Boolean. Set to make your notification appear even if computer is in do-not-disturb mode.

* `lockscreen_only`:
  Boolean. Set to make your notification appear only if computer is locked. If set, no buttons will be available.

* `poofs_on_cancel`:
  Boolean. Set to make your notification :poof when the cancel button is hit.


at
-----

The `at` property is the DateTime after which you alert will fire. Both `yo_launchd.py` and this cookbook assume your DateTime is in UTC. You should define it that way, or define a correct TZ offset.

Please note that an alert will always fire at the same time, globally - DateTimes are not native to the device on which an alert is scheduled. If you need more complicated scheduling, and are ok with an alert firing within a window defined by your chef-client launchd's frequency (ie, not at a extremely precise time), I recommend using `:send` in conjunction with `only_if` or `not_if`.

Examples:

```ruby
cpe_yo 'This alert will fire once April 1st, 2019, at or around 9:00 AM PST' do
  poofs_on_cancel true
  subtitle 'blah blah'
  info 'i am informative'
  delivery_sound 'example.mp3'
  content_image 'example.jpg'
  action :schedule
  at DateTime.parse('1st Apr 2019 09:00:00-07:00')
end
```

```ruby
cpe_yo 'This alert will always fire immediately (when the launchd runs)'
  info 'the at parameter is part of an alert\'s unique key'
  action :schedule
  at DateTime.now
end
```

Any correctly parsed DateTime will do. If you leave off a TZ offset, cpe_yo will assume you mean UTC.

```ruby
cpe_yo 'This alert will fire in next millenium'
  info 'Happy New Year!'
  action :schedule
  at DateTime.parse('1st January 3001 00:01')
end
```

See the default recipe for a couple more scheduled alert examples.

Dependencies
----------

- A Yo installation (we use Munki)
- cpe_launchd for setting up scheduling launchd
- cpe_utils
