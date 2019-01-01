# frozen_string_literal: true

RSpec.shared_examples "an endpoint that supports JSON, form, and text exchange" do |verb|
  def call_api(verb, path, params, headers)
    if params
      params = params.to_json if headers["Content-Type"] == "application/json"
      send(verb, path, params: params, headers: headers)
    else
      send(verb, path, headers: headers)
    end
  end

  if %i[get].include?(verb)
    # GET requests should support text/plain or application/json
    it "is valid with a 'text/plain' content-type header" do
      headers = default_headers
      headers["Content-Type"] = "text/plain"
      call_api(verb, path, (defined?(valid_params) ? valid_params : nil), headers)

      expect(response.successful?).to be(true), "expected successful response, got #{response.body}"
    end

    it "is valid with a 'application/json' content-type header" do
      headers = default_headers
      headers["Content-Type"] = "application/json"
      call_api(verb, path, (defined?(valid_params) ? valid_params : nil), headers)

      expect(response.successful?).to be(true), "expected successful response, got #{response.body}"
    end

    it "is not valid with other content-type headers" do
      headers = default_headers
      headers["Content-Type"] = "text/html"
      call_api(verb, path, (defined?(valid_params) ? valid_params : nil), headers)

      expect(response).to have_http_status(:bad_request)
      expect(json.dig("error", "message")).to eq("Invalid content type")
    end
  else
    # non-GET requests should support application/json or application/x-www-form-urlencoded
    it "is valid with a 'application/x-www-form-urlencoded' content-type header" do
      headers = default_headers
      headers["Content-Type"] = "application/x-www-form-urlencoded"
      call_api(verb, path, (defined?(valid_params) ? valid_params : nil), headers)

      expect(response.successful?).to be(true), "expected successful response, got #{response.body}"
    end

    it "is valid with a 'application/json' content-type header" do
      headers = default_headers
      headers["Content-Type"] = "application/json"
      call_api(verb, path, (defined?(valid_params) ? valid_params : nil), headers)

      expect(response.successful?).to be(true), "expected successful response, got #{response.body}"
    end

    it "is not valid with other content-type headers" do
      headers = default_headers
      headers["Content-Type"] = "text/html"
      call_api(verb, path, (defined?(valid_params) ? valid_params : nil), headers)

      expect(response).to have_http_status(:bad_request)
      expect(json.dig("error", "message")).to eq("Invalid content type")
    end
  end

  it "responds with V1 API by default if no accept header is provided" do
    headers = default_headers
    headers.delete("Accept")
    call_api(verb, path, (defined?(valid_params) ? valid_params : nil), headers)

    expect(response.successful?).to be(true), "expected successful response, got #{response.body}"
  end

  it "responds with v1 API if V1 accept header is specified" do
    headers = default_headers
    headers["Accept"] = "application/vnd.healer-api.v1+json"
    call_api(verb, path, (defined?(valid_params) ? valid_params : nil), headers)

    expect(request.controller_class.parent).to eq(V1)
  end

  # TODO this will necessarily change when API is versioned; at that point a new
  # default test should be introduced as a replica of this one
  it "responds with v1 API if V2 accept header is specified" do
    headers = default_headers
    headers["Accept"] = "application/vnd.healer-api.v2+json"
    call_api(verb, path, (defined?(valid_params) ? valid_params : nil), headers)

    expect(request.controller_class.parent).to eq(V1)
  end
end
