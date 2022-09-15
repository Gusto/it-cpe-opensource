# Copyright:: (c) Gusto, Inc. and its affiliates.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Cookbook:: cpe_onepassword
# Attributes:: default

default["cpe_onepassword"]["configure"] = nil
default["cpe_onepassword"]["recursively_create_if_missing"] = false
default["cpe_onepassword"]["create_if_missing"] = true
default["cpe_onepassword"]["manage_all_settings"] = false
default["cpe_onepassword"]["settings"] = {
  "security.autolock.onDeviceLock" => nil,
  "security.autolock.minutes" => nil,
  "security.clipboard.clearAfter" => nil,
  "updates.autoUpdate" => nil,
  "updates.updateChannel" => nil,
}
