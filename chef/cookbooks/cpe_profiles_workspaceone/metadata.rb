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

name 'cpe_profiles_workspaceone'
maintainer 'Gusto'
maintainer_email 'it-cpe@gusto.com'
license 'Apache-2.0'
description 'Installs/configures macOS configuration profiles via lambda + Workspace One'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '0.1.0'
supports 'mac_os_x'
depends 'cpe_workspaceone'
depends 'cpe_profiles'
depends 'uber_helpers'
