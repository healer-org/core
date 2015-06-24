RSpec.describe "procedures", type: :api do
  fixtures :cases

  let(:query_params) { {} }

  describe "POST create" do
    let(:headers) { token_auth_header.merge(json_content_headers) }
    let(:endpoint_url) { "/v1/procedures" }
    let(:the_case) { cases(:fernando_left_hip) }

    it "returns 401 if authentication headers are not present" do
      payload = { procedure: { case_id: the_case.id } }

      post(endpoint_url, payload.to_json, json_content_headers)

      expect_failed_authentication
    end

    it "returns 400 if JSON not provided" do
      payload = { procedure: { case_id: the_case.id } }

      post(endpoint_url, payload, token_auth_header)

      expect_bad_request
    end

    it "persists a new case-associated record and returns JSON" do
      attributes = {
        case_id: the_case.id
      }

      payload = query_params.merge(procedure: attributes)

      expect {
        post(endpoint_url, payload.to_json, headers)
      }.to change(Procedure, :count).by(1)

      expect_created_response

      response_record = json["procedure"]
      persisted_record = Procedure.last

      expect(persisted_record.case_id).to eq(the_case.id)
      expect(response_record["case_id"]).to eq(the_case.id)
    end
  end
end