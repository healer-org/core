# frozen_string_literal: true

RSpec.describe "teams", type: :request do
  fixtures :teams

  let(:query_params) { {} }
  let(:endpoint_root_path) { "/teams" }
  let(:headers) { default_headers }

  def response_records
    json["team"]
  end

  describe "GET show" do
    let(:persisted_record) { teams(:superdocs) }
    let(:path) { "#{endpoint_root_path}/#{persisted_record.id}" }

    it_behaves_like "a standard JSON-compliant endpoint", :get

    it "returns a single persisted record as JSON" do
      get(path, params: query_params, headers: headers)

      response_record = json["team"]

      expect(response).to have_http_status(:ok)
      expect(response_record["name"]).to eq(persisted_record.name)
    end

    it "returns 404 if there is no persisted record" do
      path = "#{endpoint_root_path}/#{persisted_record.id + 1}"

      get(path, params: query_params, headers: headers)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST create" do
    let(:path) { endpoint_root_path }
    let(:team) { teams(:op_good) }
    let(:valid_params) do
      {
        team: {
          name: "Operation Walk Mooresville"
        }
      }
    end

    it_behaves_like "a standard JSON-compliant endpoint", :post

    it "persists a new team record and returns JSON" do
      attributes = { name: "Derp" }
      payload = query_params.merge(team: attributes)

      expect {
        post(path, params: payload.to_json, headers: headers)
      }.to change(Team, :count).by(1)

      expect(response).to have_http_status(:created)

      persisted_record = Team.last

      expect(persisted_record.name).to eq("Derp")
    end
  end
end
