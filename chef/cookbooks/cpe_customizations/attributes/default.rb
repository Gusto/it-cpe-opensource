# SPDX-FileCopyrightText: Gusto, Inc.
#
# SPDX-License-Identifier: Apache-2.0

# Cookbook:: cpe_customizations
# Attributes:: default

# Teams here are applied if they appear as a substring in another team.
# For instance, if a user is in team "App Engineering" they
# will be included in the "engineering" team customization if "engineering" is a
# fuzzy_team.
default["cpe_customizations"]["fuzzy_teams"] = [
  "data",
  "design",
  "developers",
  "engineering",
]

# Teams to which the user may add themselves for self service via a local flag file
default["cpe_customizations"]["allowed_self_service_teams"] = [
  "engineering",
]
