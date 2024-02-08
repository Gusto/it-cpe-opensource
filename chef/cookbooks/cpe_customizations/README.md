# cpe_customizations

## Precedence

1. Node
1. User
1. Subteam
1. Team
1. Department
1. Company

Node customizations take precedence over all other customization types.
User customizations take precedence over team customization recipes. Team precedence is Subteam > Team > Department > Company.

## Node customizations

Node customizations apply only to individual nodes, identified by their serial number. To apply a customization to the Chef node for Mac with serial `C02DMASBQ05G`, create `cpe_customizations/recipes/node/C02DMASBQ05G.rb`. The recipe name is case insensitive.

## User customizations

Define a recipe by copying recipes/user/example.rb. Name the recipe after the target Gustie's username (their email before the @).

For instance, to apply a customization to all devices issued to Penny Pig, add `cpe_customizations/recipes/user/penny.pig.rb`.

## Team customizations

`default.rb` will iterate over `node.gustie.teams`. The teams in `mac_user_team_attributes` (`com.gustocorp.team.attributes` payload) are Company, Department, Team, and Subteam. This data is pushed directly from an Okta workflow to SimpleMDM. When attribute values are updated in SimpleMDM by automated sync, the profile is reinstalled to reflect new values as well.

### Fuzzy teams

"Fuzzy" teams are applied if they appear as a substring in another team. For instance, if a user is in team "App Ecosystem Engineering", they will be included in the "engineering" team customization if "engineering" is a fuzzy_team.
```
default["cpe_customizations"]["fuzzy_teams"] = [
  "engineering",
  "biztech"
]
```

### Self-service teams

Users may manually add themselves to teams by creating an empty `.team` file, either in `/opt/gusto/.TEAMNAME.team` on macOS or `C:\cinc\TEAMNAME.team` on Windows. Note the `.` in the macOS filename. Try not to do this too often, since there's no cleanup function if someone changes departments from Engineering to Finance.

For example, add a device to the engineering customization by running `sudo touch /opt/gusto/.engineering.team`.

The list of allowed self service teams is define in the `default["cpe_customizations"]["allowed_self_service_teams"]` attribute.

## General customization recipe patterns

Customizations can be used to amend the behavior of attributes-patterned cookbooks by changing any attribute set in `cpe_init/recipes`. For instance, one can add or overwrite the Managed Software Center managed installs list:

```ruby
node.default["cpe_munki"]["local"]["managed_installs"] += [
  "Docker",
  "Slack",
]
```

You can also add Ruby or [Chef resources](https://docs.chef.io/resource/). For executing shell scripts, it's best to use the `execute` resource.

Use `node.username` for file ownership or running a command as a specific user. For specifying paths with a home directory, use `node.homedir`.

```ruby
execute "What's my username?" do
  command "whoami"
  user node.username
  not_if { node.username.nil? }
end

file node.homedir.join(".foo") do
  owner node.username
  content "theme=solarized"
  action :create
end

```

> [!WARNING]
> This value can be incorrect if a user has changed their local account name since device enrollment.

## Generating customization recipes

Specify type - user or team - and the name. Usernames should be period separated. Team names should be snake cased `like_this`.

The simplest approach is to copy and paste `cookbooks/cpe_customizations/recipes/user/example.rb`, and modify as needed.
