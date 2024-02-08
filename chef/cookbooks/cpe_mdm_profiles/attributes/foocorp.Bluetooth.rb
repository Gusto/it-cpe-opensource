# SPDX-FileCopyrightText: Gusto, Inc.
#
# SPDX-License-Identifier: Apache-2.0

# Cookbook:: cpe_mdm_profiles
# Attributes:: foocorp.Bluetooth

default["cpe_mdm_profiles"]["foocorp.Bluetooth"] = {
  "enabled" => false,
  "payloads" => [
    {
      "PayloadType" => "com.apple.Bluetooth",
      "PayloadDisplayName" => "Bluetooth settings",
      "BluetoothAutoSeekKeyboard" => false,
      "BluetoothAutoSeekPointingDevice" => false,
    },
  ],
}
