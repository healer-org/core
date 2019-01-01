# frozen_string_literal: true

RSpec.describe "procedures", type: :request do
  fixtures :cases

  let(:query_params) { {} }
  let(:endpoint_root_path) { "/procedures" }
  let(:headers) { default_headers }

  describe "POST create" do
    let(:path) { endpoint_root_path }
    let(:the_case) { cases(:fernando_left_hip) }
    let(:valid_params) do
      {
        procedure: {
          case_id: the_case.id,
          type: "total_knee_replacement",
          version: "v1"
        }
      }
    end

    it_behaves_like "an endpoint that supports JSON, form, and text exchange", :post

    it "persists a new case-associated record and returns JSON" do
      attributes = {
        case_id: the_case.id,
        type: "a_procedure",
        version: "opwalk_2015",
        providers: { "doc_1" => { role: :primary } }
      }

      payload = query_params.merge(procedure: attributes)

      expect {
        post(path, params: payload.to_json, headers: headers)
      }.to change(Procedure, :count).by(1)

      expect(response).to have_http_status(:created)

      response_record = json["procedure"]
      persisted_record = Procedure.last

      expect(persisted_record.case_id).to eq(the_case.id)
      expect(response_record["case_id"]).to eq(the_case.id)
    end
  end
end
