# frozen_string_literal: true

RSpec.describe "teams", type: :request do
  fixtures :teams

  let(:query_params) { {} }
  let(:endpoint_root_path) { "/teams" }
  let(:headers) do
    v1_accept_header.merge(token_auth_header).merge(json_content_headers)
  end

  def response_records
    json["team"]
  end

  describe "GET show" do
    let(:persisted_record) { teams(:superdocs) }
    let(:endpoint_url) { "#{endpoint_root_path}/#{persisted_record.id}" }

    # it_behaves_like "an authentication-protected #show endpoint"

    it "returns a single persisted record as JSON" do
      get(endpoint_url, params: query_params, headers: headers)

      response_record = json["team"]

      expect_success_response
      expect(response_record["name"]).to eq(persisted_record.name)
    end

    it "returns 404 if there is no persisted record" do
      endpoint_url = "#{endpoint_root_path}/#{persisted_record.id + 1}"

      get(endpoint_url, params: query_params, headers: headers)

      expect_not_found_response
    end
  end

  describe "POST create" do
    let(:endpoint_url) { endpoint_root_path }
    let(:team) { teams(:op_good) }

    # it_behaves_like "an authentication-protected #create endpoint"

    it "returns 400 if JSON not provided" do
      payload = { team: { name: "Derp" } }

      post(endpoint_url, params: payload, headers: token_auth_header)

      expect_bad_request
    end

    it "persists a new team record and returns JSON" do
      attributes = { name: "Derp" }
      payload = query_params.merge(team: attributes)

      expect {
        post(endpoint_url, params: payload.to_json, headers: headers)
      }.to change(Team, :count).by(1)

      expect_created_response

      persisted_record = Team.last

      expect(persisted_record.name).to eq("Derp")
    end
  end
end
