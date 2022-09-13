cpe_slack Cookbook
========================
Manage Slack settings


Attributes
----------
* node['cpe_slack']['preferences']
* node['cpe_slack']['signin_token']
* node['cpe_slack']['SlackNoAutoUpdates']

This cookbook is forked from Uber, which removed it in [f5f80d5](https://github.com/uber/client-platform-engineering/commit/f5f80d539327e5e29abbd1c9157d763c79fbea4b).

The fork adds support for Slack to have a default signin domain by populating a signon token on disk. This only works if Slack is already installed and `~/Library/Application Support/Slack` or `C:/Users/#{node.console_user}/AppData/Roaming/Slack` exists. Define `node["cpe_slack"]["signin_token"]` to use. You can [get your team ID for a signon token](https://slack.com/help/articles/360041725993-Share-a-default-sign-in-file-with-members) with the help of a Slack admin or owner.

Usage
-----
The profile will manage the `com.tinyspeck.slackmacgap` preference domain with the keys in `preferences`.

The profile's organization key defaults to `Uber` unless `node['organization']` is configured in your company's custom init recipe. The profile will also use whichever prefix is set in node['cpe_profiles']['prefix'], which defaults to `com.facebook.chef`

The profile delivers a payload for the above keys in `node['cpe_slack']`. The three provided have a sensible default, which can be overridden in another recipe if desired.

This cookbook provides zero keys within the default attributes as there are many undocumented keys.

For a list of supported keys, please see Slack's [knowledge base article on enterprise deployment](https://slack.com/help/articles/360035635174-Deploy-Slack-for-macOS). At time of writing, the only supported key is `SlackNoAutoUpdates`.

For example, you could tweak the above values
```
    # Disable the ability for Slack to auto-update
    node.default['cpe_slack']['SlackNoAutoUpdates'] = true
```
