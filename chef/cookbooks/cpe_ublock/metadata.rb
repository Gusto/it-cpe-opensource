name 'cpe_ublock'
maintainer 'Gusto'
maintainer_email 'noreply@gusto.com'
license 'Apache'
description 'Writes custom configuration for uBlock Origin extension'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '0.1.0'
chef_version '>= 12.14' if respond_to?(:chef_version)

depends 'cpe_profiles'
depends 'cpe_utils'
depends 'uber_helpers'
