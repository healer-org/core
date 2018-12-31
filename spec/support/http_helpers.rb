# frozen_string_literal: true

module HTTP
  module JsonHelpers
    def json
      @json ||= JSON.parse(response.body)
    end
  end

  module ResponseHelpers
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
