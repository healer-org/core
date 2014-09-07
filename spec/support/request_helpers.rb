module Requests
  module JsonHelpers
    def json
      @json ||= JSON.parse(response.body)
    end
  end

  module ResponseHelpers
    def expect_missing_client_response
      response.code.should == "400"
      json["error"]["message"].should match(/clientId/i)
    end

    def expect_not_found_response
      response.code.should == "404"
      json["error"]["message"].should == "Not Found"
    end
  end
end