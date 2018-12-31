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
    def default_headers
      v1_accept_header.merge(json_content_headers)
    end

    def v1_accept_header
      {
        "Accept" => "application/vnd.healer-api.v1+json"
      }
    end

    def json_content_headers
      {
        "Content-Type" => "application/json"
      }
    end
  end
end
