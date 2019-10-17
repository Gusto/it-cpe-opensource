# it-cpe-opensource

This repo contains various tools used by the CPE team at Gusto to manage our endpoints and software deployment systems.

## Chef Cookbooks

- cpe_activedirectory - uses dsconfigad to adjust bind configuration on macbooks
- cpe_hot_corners - enforce a hot corner and bug users to set one
> Dependent on cpe_yo
- cpe_yo - send or schedule Yo alerts (thanks Shea Craig!).
> Dependent on Yo installation (we use Munki)
- cpe_printers - manage CUPs printers
- cpe_textexpander - manage TextExpander5 configuration and text snippets
- cpe_zoom - Manage ZoomIT configuration
> Only works with the ZoomIT package, not vanilla consumer zoom

- node_functions - Our node functions. We recommend keeping a cpe_utils/node_functions folder, and including multiple repos' node_functions file (Uber, Facebook) in a predetermined order.

## Autopromote

This script promotes munki packages between a set of json-configured catalogs. It can be adapted to any munki setup, so long as it has write access to the pkgsinfo folder. If you use a version controlled munki, you may want to remove the makecatalogs bits.

In addition to the listed requirements.txt, autopromote.py expects munkilib to be install to /usr/local/munki.
