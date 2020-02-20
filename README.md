# it-cpe-opensource

This repo contains various tools used by the CPE team at Gusto to manage our endpoints and software deployment systems.

## Chef Cookbooks

CPE attributes-API patterned chef cookbooks which support user/team/node customization. See cookbook readmes for dependencies and usage.

### node_functions

Our node functions. We recommend keeping a cpe_utils/node_functions folder, and including multiple repos' node_functions file (Uber, Facebook) in a predetermined order.

## Autopromote

This script promotes munki packages between a set of json-configured catalogs. It can be adapted to any munki setup, so long as it has write access to the pkgsinfo folder. If you use a version controlled munki, you may want to remove the makecatalogs bits.

In addition to the listed requirements.txt, autopromote.py expects munkilib to be install to /usr/local/munki.
