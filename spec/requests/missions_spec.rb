# frozen_string_literal: true

RSpec.describe "missions", type: :request do
  fixtures :missions, :teams

  let(:default_params) { {} }
  let(:endpoint_root_path) { "/missions" }
  let(:headers) { default_headers }

  def response_records
    json["missions"]
  end

  describe "GET show" do
    let(:persisted_record) { missions(:gt_2015) }
    let(:path) { "#{endpoint_root_path}/#{persisted_record.id}" }

    it_behaves_like "an endpoint that supports JSON, form, and text exchange", :get

    it "returns a single persisted record as JSON" do
      get(path, params: default_params, headers: headers)

      response_record = json["mission"]

      expect(response).to have_http_status(:ok)
      expect(response_record["name"]).to eq(persisted_record.name)
    end

    it "returns 404 if there is no persisted record" do
      path = "#{endpoint_root_path}/#{persisted_record.id + 1}"

      get(path, params: default_params, headers: headers)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST create" do
    let(:path) { endpoint_root_path }
    let(:mission) { missions(:gt_2015) }
    let(:valid_params) do
      {
        mission: {
          name: "New Mission",
          team_ids: [teams(:op_good).id]
        }
      }
    end

    it_behaves_like "an endpoint that supports JSON, form, and text exchange", :post

    it "persists a new mission record and returns JSON" do
      params = default_params.merge(valid_params)

      expect {
        post(path, params: params.to_json, headers: headers)
      }.to change(Mission, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(json.dig("mission", "name")).to eq("New Mission")
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
