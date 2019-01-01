# frozen_string_literal: true

RSpec.shared_examples "a standard JSON-compliant endpoint" do |verb|
  def call_api(verb, path, params, headers)
    if params
      send(verb, path, params: params.to_json, headers: headers)
    else
      send(verb, path, headers: headers)
    end
  end

  it "is valid with a content-type header that is accepted" do
    call_api(verb, path, (defined?(valid_params) ? valid_params: nil), default_headers)

    expect(response.successful?).to be(true), "expected successful response, got #{response.body}"
  end

  it "is invalid with a content-type header that is not accepted" do
    bad_headers = default_headers
    bad_headers["Content-Type"] = "text/plain"
    call_api(verb, path, (defined?(valid_params) ? valid_params : nil), bad_headers)

    expect(response).to have_http_status(:bad_request)
    expect(json.dig("error", "message")).to eq("Content-Type must be application/json")
  end

  if %i[get delete].include?(verb)
    it "is valid without a content-type header" do
      bad_headers = default_headers
      bad_headers.delete("Content-Type")
      call_api(verb, path, (defined?(valid_params) ? valid_params : nil), bad_headers)

      expect(response).to have_http_status(:ok)
    end
  else
    it "is invalid without a content-type header" do
      bad_headers = default_headers
      bad_headers.delete("Content-Type")
      call_api(verb, path, (defined?(valid_params) ? valid_params : nil), bad_headers)

      expect(response).to have_http_status(:bad_request)
      expect(json.dig("error", "message")).to eq("Content-Type must be application/json")
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
