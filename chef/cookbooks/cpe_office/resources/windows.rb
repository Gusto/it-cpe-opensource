# Cookbook:: cpe_office
# Resources:: windows
#
# Copyright:: (c) 2021-present, Gusto, Inc.
# All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
unified_mode true
provides :cpe_office, os: "windows"
default_action :manage

action :manage do
  return unless node["cpe_office"]["configure"]
  excel_prefs = node["cpe_office"]["win"]["excel"]
  powerpoint_prefs = node["cpe_office"]["win"]["powerpoint"]
  word_prefs = node["cpe_office"]["win"]["word"]
  global_prefs = node["cpe_office"]["win"]["global"]

  if [
    excel_prefs,
    powerpoint_prefs,
    word_prefs,
    global_prefs,
  ].all?(&:empty?)
    Chef::Log.info("#{cookbook_name}: prefs not found.")
    return
  end

  unless word_prefs.empty?
    word_prefs.each do |path, pref|
      pref.each do |key_name, values|
        reg_values = [{
            name: key_name,
            type: values.key?(:type) ? values[:type] : :dword,
            data: values[:data],
        }]
        if values[:data].nil?
          registry_key "Word #{path} : #{key_name}" do
            key "HKEY_CURRENT_USER\\Software\\Policies\\Microsoft\\Office\\16.0\\Word\\#{path}"
            values reg_values
            recursive true
            action :delete
          end
        else
          registry_key "Word #{path} : #{key_name}" do
            key "HKEY_CURRENT_USER\\Software\\Policies\\Microsoft\\Office\\16.0\\Word\\#{path}"
            values reg_values
            recursive true
            action :create
          end
        end
      end
    end
  end

  unless excel_prefs.empty?
    excel_prefs.each do |path, pref|
      pref.each do |key_name, values|
        reg_values = [{
            name: key_name,
            type: values.key?(:type) ? values[:type] : :dword,
            data: values[:data],
        }]
        if values[:data].nil?
          registry_key "Excel #{path} : #{key_name}" do
            key "HKEY_CURRENT_USER\\Software\\Policies\\Microsoft\\Office\\16.0\\Excel\\#{path}"
            values reg_values
            recursive true
            action :delete
          end
        else
          registry_key "Excel #{path} : #{key_name}" do
            key "HKEY_CURRENT_USER\\Software\\Policies\\Microsoft\\Office\\16.0\\Excel\\#{path}"
            values reg_values
            recursive true
            action :create
          end
        end
      end
    end
  end

  unless powerpoint_prefs.empty?
    powerpoint_prefs.each do |path, pref|
      pref.each do |key_name, values|
        reg_values = [{
            name: key_name,
            type: values.key?(:type) ? values[:type] : :dword,
            data: values[:data],
        }]
        if values[:data].nil?
          registry_key "Powerpoint #{path} : #{key_name}" do
            key "HKEY_CURRENT_USER\\Software\\Policies\\Microsoft\\Office\\16.0\\Powerpoint\\#{path}"
            values reg_values
            recursive true
            action :delete
          end
        else
          registry_key "Powerpoint #{path} : #{key_name}" do
            key "HKEY_CURRENT_USER\\Software\\Policies\\Microsoft\\Office\\16.0\\Powerpoint\\#{path}"
            values reg_values
            recursive true
            action :create
          end
        end
      end
    end
  end

  unless global_prefs.empty?
    global_prefs.each do |path, pref|
      pref.each do |key_name, values|
        reg_values = [{
            name: key_name,
            type: values.key?(:type) ? values[:type] : :dword,
            data: values[:data],
        }]
        if values[:data].nil?
          registry_key "Office #{path} : #{key_name}" do
            key "HKEY_CURRENT_USER\\Software\\Policies\\Microsoft\\Office\\16.0\\#{path}"
            values reg_values
            recursive true
            action :delete
          end
        else
          registry_key "Office #{path} : #{key_name}" do
            key "HKEY_CURRENT_USER\\Software\\Policies\\Microsoft\\Office\\16.0\\#{path}"
            values reg_values
            recursive true
            action :create
          end
        end
      end
    end
  end
end
