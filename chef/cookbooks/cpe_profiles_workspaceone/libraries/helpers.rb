class Chef
  class Node
    def install_profile_via_lambda(profile)
      request = {
        name: profile[:name],
        hash: profile[:hash],
        profile: profile[:payload],
        action: 'install',
      }

      send_lambda_profile_request(request)
    end

    def remove_profile_via_lambda(hashed_name)
      request = {
        name: hashed_name,
        serial: node.serial,
        action: 'remove'
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
      response = http.post('/default/ws1_profile_middleware', data, headers)
      status = response['statusCode']
      if status != 200 && status != nil
        fail "Recieved error #{status} from lambda middleware: #{response}"
      end

      Chef::Log.info(response)
      response
    end
  end
end
