#
#
# Cookbook Name:: cpe_printers
# Attributes:: default
#
# Gusto CPE Chef Cookbooks
# Copyright 2019 ZenPayroll, Inc., dba Gusto
#
# This product includes software developed by
# ZenPayroll, Inc., dba Gusto (http://www.gusto.com/).
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

default['cpe_printers']['configure'] = false
default['cpe_printers']['prefix'] = 'gusto'
default['cpe_printers']['reset_cups_if_neccessary'] = true
default['cpe_printers']['delete_mcx_printers'] = false

# Printers to add. All printers must define a DisplayName and a DeviceURI
# Alternatively, a printer can define just a QueueName if it is a printer queue
# Dobby/Jason do not have a DNS name

default['cpe_printers']['printers'] = []

# Applied to above hashes if not defined.
default['cpe_printers']['defaults'] = {
  'Model' => 'Generic PostScript Printer',
  'PPDURL' => '/System/Library/Frameworks/ApplicationServices.framework/Versions/A/Frameworks/PrintCore.framework/Resources/Generic.ppd',
  'printer-is-shared' => false
}

# Legacy printer names which we will remove via lpadmin
# Printers added via profile are always "mcx_n" so far as lpadmin is concerned,
# there is no risk of deleting a profile printer.
default['cpe_printers']['printers_to_delete'] = [
  'Your_evil_corporate_printer'
]
