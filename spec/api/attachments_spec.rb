def setup_attachment_attributes(record_type, record_id)
  file_path = "#{Rails.root}/spec/attachments/1x1.png"
  file = File.open(file_path, "rb")
  @attachment_attributes = {
    data: Base64.encode64(file.read),
    file_name: File.basename(file_path),
    content_type: `file -Ib #{file_path}`.delete("\n"),
    record_id: record_id,
    record_type: record_type
  }
end

RSpec.describe "attachments", type: :api do
  fixtures :cases, :patients

  let(:query_params) { {} }
  let(:endpoint_root_path) { "/v1/attachments" }

  describe "POST create" do
    let(:headers) { token_auth_header.merge(json_content_headers) }
    let(:endpoint_url) { endpoint_root_path }

    it_behaves_like "an authentication-protected #create endpoint"

    it "creates an attachment on a case" do
      persisted_case = cases(:fernando_left_hip)
      setup_attachment_attributes("Case", persisted_case.id)
      payload = query_params.merge(attachment: @attachment_attributes)

      expect(persisted_case.attachments.size).to eq(0)

      expect {
        post(endpoint_url, payload.to_json, headers)
      }.to change(Attachment, :count).by(1)
      expect_created_response

      expect(persisted_case.reload.attachments.size).to eq(1)

      get "/v1/cases/#{persisted_case.id}", query_params.merge(showAttachments: true), headers

      expect_success_response
      response_record = json["case"]
      expect(response_record["attachments"].size).to eq(1)
      returned_attachment = response_record["attachments"].first
      expect(returned_attachment["documentFileName"]).to eq(@attachment_attributes[:file_name])
    end

    it "returns 404 if a record is not found" do
      expect(Case.find_by_id(99_999)).to eq(nil)
      setup_attachment_attributes("Case", 99_999)
      payload = query_params.merge(attachment: @attachment_attributes)

      expect {
        post(endpoint_url, payload.to_json, headers)
      }.to_not change(Attachment, :count)
      expect_not_found_response
    end

    %i(record_id record_type data content_type file_name).each do |required|
      it "returns 400 if #{required} attribute is not supplied" do
        persisted_case = cases(:fernando_left_hip)
        setup_attachment_attributes("Case", persisted_case.id)

        @attachment_attributes.delete(required)
        payload = query_params.merge(attachment: @attachment_attributes)

        expect {
          post(endpoint_url, payload.to_json, headers)
        }.to_not change(Attachment, :count)
        expect_bad_request
        expect(json["error"]["message"]).to match(/#{required}/)
      end
    end
  end
end
