name 'cpe_activedirectory'
maintainer 'Gusto CPE'
maintainer_email 'it-cpe@gusto.com'
description 'Using dsconfigad to apply Active Directory settings'
version '0.1.0'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
chef_version '>= 14.14'

depends 'cpe_utils'
depends 'uber_helpers'
