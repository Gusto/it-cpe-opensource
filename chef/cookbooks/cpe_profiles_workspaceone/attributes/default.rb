# Copyright (c) Gusto, Inc. and its affiliates.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Cookbook Name:: cpe_profiles_workspaceone
# Attributes:: default

default["cpe_profiles_workspaceone"] = {}
default["cpe_profiles_workspaceone"]["prefix"] = nil
default["cpe_profiles_workspaceone"]["remote_profiles"] = {
  "user": [],
  "device": [],
}
default["cpe_profiles_workspaceone"]["forced_profiles"] = []
default["cpe_profiles_workspaceone"]["lambda_config"] = {
  "url" => nil,
  "key" => nil,
  "use_hubcli" => false
}
default["cpe_profiles_workspaceone"]["__cleanup"] = []
