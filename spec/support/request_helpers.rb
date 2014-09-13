module Requests
  module JsonHelpers
    def json
      @json ||= JSON.parse(response.body)
    end
  end

  module ResponseHelpers
    def expect_failed_authentication
      response.code.should == "401"
      json["error"]["message"].should == "Bad credentials"
    end

    def expect_not_found_response
      response.code.should == "404"
      json["error"]["message"].should == "Not Found"
    end
  end

  module HeaderHelpers
    def token_auth_header
      {"HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Token.encode_credentials("ABCDEF0123456789")}
    end

    def json_content_header
      {"Content-Type" => "application/json"}
    end
  end
end