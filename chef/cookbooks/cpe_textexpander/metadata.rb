#
name 'cpe_textexpander'
maintainer 'Gusto IT CPE'
maintainer_email 'it-cpe@gusto.com'
license 'All rights reserved'
description 'Configures TextExpander 5'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
# The version should always be '0.1.0', and you'll never ever change it.
version '0.1.0'

# If you use any of the CPE node functions, or cpe_remote, you'll need these
# in your metadata.
# Any cookbooks you depend on for any reason should be listed here.
depends 'cpe_utils'
