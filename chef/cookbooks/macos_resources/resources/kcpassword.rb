# SPDX-FileCopyrightText: Gusto, Inc.
#
# SPDX-License-Identifier: Apache-2.0

# This resource includes code originally written by Microsoft, released under the MIT expat license in
# https://github.com/microsoft/macos-cookbook/blob/f41535f31754a8c4084d030e86488e2a9f1bb7f5/libraries/macos_user.rb

# Cookbook:: macos_resources
# Resource:: kcpassword

resource_name :kcpassword
unified_mode true
provides :kcpassword, os: "darwin"
default_action :create

description "Writes kcpassword file."

property :password, String,
  description: "Password to XOR, ideally using an encrypted data bag item."

action_class do
  def kcpassword_hash(password)
    bits = magic_bits
    obfuscated = []
    padded(password).each do |char|
      obfuscated.push(bits[0] ^ char)
      bits.rotate!
    end
    obfuscated.pack("C*")
  end

  def magic_bits
    [125, 137, 82, 35, 210, 188, 221, 234, 163, 185, 31]
  end

  def magic_len
    magic_bits.length
  end

  def padded(password)
    padding = magic_len - (password.length % magic_len)
    padding_size = padding > 0 ? padding : 0
    translated(password) + ([0] * padding_size)
  end

  def translated(password)
    password.split("").map(&:ord)
  end

  def decode_kcpassword(kcpass)
    decoded = kcpass.bytes.to_a.each_slice(magic_bits.length).map do |kc|
      kc.each_with_index.map { |byte, idx| byte ^ magic_bits[idx] }.map(&:chr).join
    end.join.sub(/\x00.*$/, "")
    return decoded
  end
end

action :create do
  if new_resource.password.nil?
    raise "Must provide a password to encode."
  end

  file "/etc/kcpassword" do
    content kcpassword_hash(new_resource.password)
    mode "0600"
    owner "root"
    group "wheel"
    sensitive true
  end
end

action :delete do
  file "/etc/kcpassword" do
    action :delete
    sensitive true
  end
end
