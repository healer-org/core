# frozen_string_literal: true

RSpec.describe "missions", type: :request do
  fixtures :missions, :teams

  let(:default_params) { {} }
  let(:endpoint_root_path) { "/missions" }

  def response_records
    json["missions"]
  end

  describe "GET show" do
    let(:headers) { token_auth_header }
    let(:persisted_record) { missions(:gt_2015) }
    let(:endpoint_url) { "#{endpoint_root_path}/#{persisted_record.id}" }

    # it_behaves_like "an authentication-protected #show endpoint"

    it "returns a single persisted record as JSON" do
      get(endpoint_url, params: default_params, headers: headers)

      response_record = json["mission"]

      expect_success_response
      expect(response_record["name"]).to eq(persisted_record.name)
    end

    it "returns 404 if there is no persisted record" do
      endpoint_url = "#{endpoint_root_path}/#{persisted_record.id + 1}"

      get(endpoint_url, params: default_params, headers: headers)

      expect_not_found_response
    end
  end

  describe "POST create" do
    let(:headers) { token_auth_header.merge(json_content_headers) }
    let(:endpoint_url) { endpoint_root_path }
    let(:mission) { missions(:gt_2015) }
    let(:valid_attrs) do
      {
        name: "New Mission",
        team_ids: [teams(:op_good).id]
      }
    end

    # it_behaves_like "an authentication-protected #create endpoint"

    it "returns 400 if JSON not provided" do
      params = { mission: { name: "Malformed Mission" } }

      post(endpoint_url, params: params, headers: token_auth_header)

      expect(response).to have_http_status(:bad_request)
    end

    it "persists a new mission record and returns JSON" do
      params = default_params.merge(mission: valid_attrs.merge(name: "Helping People"))

      expect {
        post(endpoint_url, params: params.to_json, headers: headers)
      }.to change(Mission, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(json.dig("mission", "name")).to eq("Helping People")
    end

    it "allows multiple teams to be assigned on create"
    it "validates the mission name is present"
    it "validates the country is known, if provided"
  end

  describe "PATCH update" do
    it "validates at least one team on the mission"
    it "allows multiple teams to be assigned to the mission"
    it "validates the mission name is present"
    it "validates the country is known, if provided"
  end
end
