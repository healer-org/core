module Requests
  module JsonHelpers
    def json
      @json ||= JSON.parse(response.body)
    end
  end

  module ResponseHelpers
    def expect_failed_authentication
      expect(response.code).to eq("401")
      expect(json["error"]["message"]).to eq("Bad credentials")
    end

    def expect_not_found_response
      expect(response.code).to eq("404")
      expect(json["error"]["message"]).to eq("Not Found")
    end

    def response_ids_for(response_records)
      response_records.map{ |r| r["id"] }
    end

    def pluck_response_record(response_records, lookup_id)
      response_records.detect{ |r| r["id"] == lookup_id }
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