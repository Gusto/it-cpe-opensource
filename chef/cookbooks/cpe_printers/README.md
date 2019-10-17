cpe_printers Cookbook
==================

Requirements
------------
Mac OS X

Attributes
----------
* node['cpe_printers']['configure']
* node['cpe_printers']['printers']
* node['cpe_printers']['printers_to_delete']
* node['cpe_printers']['prefix'] - Defaults to node['organization'] if nil
* node['cpe_printers']['defaults']
* node['cpe_printers']['delete_mcx_printers']
* node['cpe_printers']['reset_cups_if_neccessary']

Usage
-----
This cookbook offers idempotent management of CUPS printers on a Macbook. `lpadmin` is used to interact with the CUPS config.

All printers have a cookbook-generated identifier, which includes the prefix defined in attributes. Much like cpe_profiles, if a prefixed printer is discovered, but not listed in the current printers list, it will be removed. Any recipe converging prior to `cpe_printers::default` can append to `node['cpe_printers']['printers']`.

Printers should define a `DisplayName` and a `DeviceURI`, at minimum. Values in the defaults array will be added to every printer definition.

Printers listed in printers_to_delete will be removed (in addition to prefix'd, unlisted printers). Printers installed via profile will be deleted if `node['cpe_printers']['delete_mcx_printers']` is set.

Todo
-----

Rewrite to support the post-cups era (Catalina) if necessary.

Dependencies
----------

- cpe_utils' printers method
