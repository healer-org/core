RSpec.describe "missions", type: :api do
  fixtures :missions

  let(:query_params) { {} }
  let(:endpoint_root_path) { "/v1/missions" }

  def response_records
    json["missions"]
  end

  describe "GET show" do
    let(:headers) { token_auth_header }
    let(:persisted_record) { missions(:gt_2015) }
    let(:endpoint_url) { "#{endpoint_root_path}/#{persisted_record.id}" }

    it_behaves_like "an authentication-protected #show endpoint"

    it "returns a single persisted record as JSON" do
      get(endpoint_url, query_params, headers)

      response_record = json["mission"]

      expect_success_response
      expect(response_record["name"]).to eq(persisted_record.name)
    end

    it "returns 404 if there is no persisted record" do
      endpoint_url = "#{endpoint_root_path}/#{persisted_record.id + 1}"

      get(endpoint_url, query_params, headers)

      expect_not_found_response
    end
  end

  describe "POST create" do
    let(:headers) { token_auth_header.merge(json_content_headers) }
    let(:endpoint_url) { endpoint_root_path }
    let(:mission) { missions(:gt_2015) }

    it_behaves_like "an authentication-protected #create endpoint"

    it "returns 400 if JSON not provided" do
      payload = { mission: { name: "Malformed Mission" } }

      post(endpoint_url, payload, token_auth_header)

      expect_bad_request
    end

    it "persists a new mission record and returns JSON" do
      attributes = { name: "New Mission" }
      payload = query_params.merge(mission: attributes)

      expect {
        post(endpoint_url, payload.to_json, headers)
      }.to change(Mission, :count).by(1)

      expect_created_response

      persisted_record = Mission.last

      expect(persisted_record.name).to eq("New Mission")
    end
  end

  it "validates at least one team on the mission"
  it "allows multiple teams to be assigned to the mission"
  it "validates the mission name is present"
  it "validates the country is known, if provided"

end
