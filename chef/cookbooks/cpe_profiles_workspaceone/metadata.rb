# Copyright (c) Gusto, Inc. and its affiliates.
name 'cpe_profiles_workspaceone'
maintainer 'Gusto'
maintainer_email 'it-cpe@gusto.com'
license 'Apache-2.0'
description 'Installs/configures macOS configuration profiles via lambda + Workspace One'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '0.1.0'
supports 'mac_os_x'
depends 'cpe_workspaceone'
