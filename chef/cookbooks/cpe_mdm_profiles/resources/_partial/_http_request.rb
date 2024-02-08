# SPDX-FileCopyrightText: Gusto, Inc.
#
# SPDX-License-Identifier: Apache-2.0

# Cookbook:: cpe_mdm_profiles

def send_profile_request(action, hashed_name, additional_parameters = {})
  request = {
    action: action,
    device_id: node.default["cpe_mdm_profiles"]["middleware_config"]["device_id"],
    environment: node.default["cpe_mdm_profiles"]["middleware_config"]["environment"],
    name: hashed_name,
  }.merge!(additional_parameters)

  Chef::Log.info("Requesting #{action} for #{hashed_name}.")

  data = request.to_json
  Chef::Log.debug(data)

  missing_attrs = [
    "device_id",
    "environment",
    "url_data_bag_name",
    "key_data_bag_name",
    "middleware_name",
  ].to_h { |attribute| [attribute, node.default["cpe_mdm_profiles"]["middleware_config"][attribute].nil?] }
                  .select { |_, v| v == true }
                  .keys

  unless missing_attrs.empty?
    Chef::Log.warn("Skipping profiles HTTP request.Unpopulated node attributes: #{missing_attrs.join(', ')}.")
    return
  end

  http = Chef::HTTP.new(data_bag_item("foo", "bar")[node.default["cpe_mdm_profiles"]["middleware_config"]["url_data_bag_name"]])
  middleware_name = node.default["cpe_mdm_profiles"]["middleware_config"]["middleware_name"]
  response = JSON.parse(
    http.post("/default/#{middleware_name}",
      data,
      { "x-api-key": data_bag_item("foo", "bar")[node.default["cpe_mdm_profiles"]["middleware_config"]["key_data_bag_name"]] }
    )
  )
  status = response["statusCode"]

  has_hidden_error = response.key?("errorMessage") && response.key?("stackTrace")

  if (status && status.to_i >= 400) || http.last_response.code.to_i >= 400 || has_hidden_error
    # Profile is already assigned, but install has not completed due to an error or pending installation request.
    if status == 409
      Chef::Log.warn("Failed to #{request[:action]} #{request[:name]}! Profile assignment state is already correct, but the MDM command is pending or failed. Skipping.")
    else
      raise "Received error #{status} from #{middleware_name}: #{response}. Event: #{data}"
    end
  end

  Chef::Log.info("#{request[:name]} middleware response: #{response}")

  response
end
