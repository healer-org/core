# frozen_string_literal: true

def attachment_attributes_for(record_type, record_id)
  file_path = "#{Rails.root}/spec/attachments/1x1.png"
  file = File.open(file_path, "rb")
  content_type = MimeMagic.by_magic(file).type
  {
    data: Base64.encode64(file.read),
    file_name: File.basename(file_path),
    content_type: content_type,
    record_id: record_id,
    record_type: record_type
  }
end

RSpec.describe "attachments", type: :request do
  fixtures :cases, :patients

  let(:query_params) { {} }
  let(:endpoint_root_path) { "/attachments" }
  let(:headers) { default_headers }

  describe "POST create" do
    let(:path) { endpoint_root_path }
    let(:persisted_case) { cases(:fernando_left_hip) }
    let(:valid_params) do
      {
        attachment: attachment_attributes_for("Case", persisted_case.id)
      }
    end

    it "creates an attachment on a case" do
      attachment_attributes = attachment_attributes_for("Case", persisted_case.id)
      payload = query_params.merge(attachment: attachment_attributes)

      expect(persisted_case.attachments.size).to eq(0)

      expect {
        post(path, params: payload.to_json, headers: headers)
      }.to change(Attachment, :count).by(1)
      expect(response).to have_http_status(:created)

      expect(persisted_case.reload.attachments.size).to eq(1)

      get("/cases/#{persisted_case.id}", params: query_params.merge(showAttachments: true), headers: headers)

      expect(response).to have_http_status(:ok)
      response_record = json["case"]
      expect(response_record["attachments"].size).to eq(1)
      returned_attachment = response_record["attachments"].first
      expect(returned_attachment["documentFileName"]).to eq(attachment_attributes[:file_name])
    end

    it "returns 404 if a record is not found" do
      expect(Case.find_by_id(99_999)).to eq(nil)
      attachment_attributes = attachment_attributes_for("Case", 99_999)
      payload = query_params.merge(attachment: attachment_attributes)

      expect {
        post(path, params: payload.to_json, headers: headers)
      }.to_not change(Attachment, :count)
      expect(response).to have_http_status(:not_found)
    end

    %i[record_id record_type data content_type file_name].each do |required|
      it "returns 400 if #{required} attribute is not supplied" do
        persisted_case = cases(:fernando_left_hip)
        attachment_attributes = attachment_attributes_for("Case", persisted_case.id)

        attachment_attributes.delete(required)
        payload = query_params.merge(attachment: attachment_attributes)

        expect {
          post(path, params: payload.to_json, headers: headers)
        }.to_not change(Attachment, :count)
        expect(response).to have_http_status(:bad_request)
        expect(json["error"]["message"]).to match(/#{required}/)
      end
    end
  end
end
