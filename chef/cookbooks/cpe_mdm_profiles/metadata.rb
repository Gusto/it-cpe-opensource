name "cpe_mdm_profiles"
maintainer "Gusto"
maintainer_email "noreply@gusto.com"
license "Apache-2.0"
description "Installs/configures macOS configuration profiles via external middleware"
version "0.1.0"
supports "mac_os_x"
chef_version ">= 16.0"

depends "gusto_helpers" # Because we use get_node_object
