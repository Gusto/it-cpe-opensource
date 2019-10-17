cpe_textexpander Cookbook
=====================
Provides an example cookbook to use as a template.

Requirements
------------
* some OS

Attributes
----------
* node['cpe_textexpander']['configure']

* node['cpe_textexpander']['snippets_settings']
* node['cpe_textexpander']['snippets_settings']['snippetPlists']
* node['cpe_textexpander']['global_settings']
* node['cpe_textexpander']['preserve_existing']
* node['cpe_textexpander']['managed_snippet_label']

Usage
-----
This cookbook manages the snippet settings and the global preference domain for TextExpander.app.

Users/teams may define custom snippets by appending to the `node['cpe_textexpander']['snippets_settings']['snippetPlists']` array.

Updates are disabled by default.

### Example ReadMe

* `configure`

  `true` -> things get done

* `preserve_existing`
  * Perform a DeepMerge with existing snippet settings (no effect on global settings)

* `managed_snippet_label`
  * Like cpe_profiles, cpe_textexpander will remove existing snippets with this label and label managed snippet with it
    `node['organization']` if nil

* `snippets_settings` dictionary descriping settings in `/Users/#{node.console_user}/Library/Application\ Support/TextExpander/Settings.textexpandersettings/group_*.xml`
  * `snippetPlists`
    Array of snippets. Please see the commented example in `attributes/default.rb`

Note: both snippetPlists and other settings are DeepMerged into existing config if `preserve_existing` is `true`

* `global_settings` describes settings to apply to the global - hopefully self explanatory keys. Booleans are integer 1 & 0 unless otherwise indicated
  * `SUEnableAutomaticChecks`
    Check for updates from TextExpander's servers


Dependencies
----------

- TextExpander5 install

Todo
----------

Test with TextExpander6
