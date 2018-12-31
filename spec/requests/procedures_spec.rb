# frozen_string_literal: true

RSpec.describe "procedures", type: :request do
  fixtures :cases

  let(:query_params) { {} }
  let(:endpoint_root_path) { "/procedures" }

  describe "POST create" do
    let(:headers) { token_auth_header.merge(json_content_headers) }
    let(:endpoint_url) { endpoint_root_path }
    let(:the_case) { cases(:fernando_left_hip) }

    # it_behaves_like "an authentication-protected #create endpoint"

    it "returns 400 if JSON not provided" do
      payload = { procedure: { case_id: the_case.id } }

      post(endpoint_url, params: payload, headers: token_auth_header)

      expect_bad_request
    end

    it "persists a new case-associated record and returns JSON" do
      attributes = {
        case_id: the_case.id,
        type: "a_procedure",
        version: "opwalk_2015",
        providers: { "doc_1" => { role: :primary } }
      }

      payload = query_params.merge(procedure: attributes)

      expect {
        post(endpoint_url, params: payload.to_json, headers: headers)
      }.to change(Procedure, :count).by(1)

      expect_created_response

      response_record = json["procedure"]
      persisted_record = Procedure.last

      expect(persisted_record.case_id).to eq(the_case.id)
      expect(response_record["case_id"]).to eq(the_case.id)
    end
  end
end
