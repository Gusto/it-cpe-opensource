#

name 'cpe_yo'
maintainer 'Gusto, Inc'
maintainer_email 'it-cpe@gusto.com'
license 'BSD'
description 'Wrapper library for yo alerts and yo alert scheduling'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '0.1.0'
author 'Harry Seeber'

depends 'cpe_utils'
depends 'cpe_launchd'

gem 'CFPropertyList'
