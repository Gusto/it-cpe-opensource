class Chef
  class Node
    def install_profile_via_lambda(profile, parameters: {})
      request = {
        name: profile[:name],
        profile: profile[:payload],
        serial: node.serial,
        action: 'install',
      }

      Chef::Log.info("Sending profile #{request[:name]} for creation and assignment on Workspace One.")

      defaults = {
        skip_creation: false,
        remote_install_requested: false
      }
      request.merge!(
        defaults.merge(parameters.reject { |k, _| request.keys.include?(k) })
      )

      send_lambda_profile_request(request)
    end

    def remove_profile_via_lambda(hashed_name)
      request = {
        name: hashed_name,
        serial: node.serial,
        action: 'remove',
        skip_creation: true,
        remote_install_requested: false
      }

      send_lambda_profile_request(request)
    end

    def send_lambda_profile_request(request)
      # FIXME these should be cookbook attributes (url, etc)
      url = node['cpe_profiles_workspaceone']['lambda_config']['url']
      headers = { "x-api-key": node['cpe_profiles_workspaceone']['lambda_config']['key'] }
      data = request.to_json
      Chef::Log.debug(data)
      http = Chef::HTTP.new(url)
      response = JSON.parse(http.post('/default/ws1_profile_middleware', data, headers))
      status = response['statusCode']

      has_hidden_error = response.key?("errorMessage") && response.key?("stackTrace")

      if (status != nil && status.to_i >= 400) || http.last_response.code.to_i >= 400 || has_hidden_error
        fail "Recieved error #{status} from lambda middleware: #{response}"
      end

      Chef::Log.info(response)

      response
    end
  end
end
