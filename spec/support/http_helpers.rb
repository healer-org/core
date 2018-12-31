# frozen_string_literal: true

module HTTP
  module JsonHelpers
    def json
      @json ||= JSON.parse(response.body)
    end
  end

  module ResponseHelpers
    def expect_success_response
      expect(response.status).to eq(200)
    end

    def expect_created_response
      expect(response.status).to eq(201)
    end

    def expect_bad_request
      expect(response.status).to eq(400)
    end

    def expect_failed_authentication
      expect(response.status).to eq(401)
    end

    def expect_not_found_response
      expect(response.status).to eq(404)
      expect(json["error"]["message"]).to eq("Not Found")
    end

    def response_ids_for(response_records)
      response_records.map { |r| r["id"] }
    end

    def pluck_response_record(response_records, lookup_id)
      response_records.detect { |r| r["id"] == lookup_id }
    end
  end

  module HeaderHelpers
    def token_auth_header
      test_key = "test-key-12345"
      {
        "HTTP_AUTHORIZATION" =>
        ActionController::HttpAuthentication::Token.encode_credentials(test_key)
      }
    end

    def json_content_headers
      {
        "Content-Type" => "application/json",
        "CONTENT_TYPE" => "application/json"
      }
    end
  end
end
