require "spec_helper"

def setup_attachment_attributes(record_type, record_id)
    file_path = "#{Rails.root}/spec/attachments/1x1.png"
    file = File.open(file_path, "rb")
    @attachment_attributes = {
      data: Base64.encode64(file.read()),
      file_name: File.basename(file_path),
      content_type: `file -Ib #{file_path}`.gsub(/\n/,""),
      record_id: record_id,
      record_type: record_type
    }
end

describe "attachments", type: :api do
  fixtures :cases

  let(:query_params) { {} }

  describe "POST create" do
    let(:headers) { token_auth_header.merge(json_content_header) }

    it "returns 401 if authentication headers are not present" do
      ff = fixture_file_upload("#{Rails.root}/spec/attachments/1x1.png", "image/png")

      post "/attachments",
           attachment: { path: ff.path }.to_json,
           "Content-Type" => "application/json"

      expect_failed_authentication
    end

    it "creates an attachment on a case" do
      persisted_case = cases(:fernando_left_hip)
      setup_attachment_attributes("Case", persisted_case.id)

      persisted_case.attachments.size.should == 0

      expect {
        post "/attachments",
             query_params.merge(attachment: @attachment_attributes).to_json,
             headers
      }.to change(Attachment, :count).by(1)
      response.code.should == "201"

      persisted_case.reload.attachments.size.should == 1

      get "/cases/#{persisted_case.id}", query_params.merge(show_attachments: true), headers

      response.code.should == "200"
      response_record = json["case"]
      response_record["attachments"].size.should == 1
      returned_attachment = response_record["attachments"].first
      returned_attachment["documentFileName"].should == @attachment_attributes[:file_name]
    end

    it "returns 400 if a record id is not supplied" do
      persisted_case = cases(:fernando_left_hip)
      setup_attachment_attributes("Case", persisted_case.id)

      @attachment_attributes.delete(:record_id)

      expect {
        post "/attachments",
             query_params.merge(attachment: @attachment_attributes).to_json,
             headers
      }.to_not change(Attachment, :count)
      response.code.should == "400"
    end

    it "returns 400 if a record type is not supplied" do
      persisted_case = cases(:fernando_left_hip)
      setup_attachment_attributes("Case", persisted_case.id)

      @attachment_attributes.delete(:record_type)

      expect {
        post "/attachments",
             query_params.merge(attachment: @attachment_attributes).to_json,
             headers
      }.to_not change(Attachment, :count)
      response.code.should == "400"
    end

    it "returns 404 if a record is not found" do
      Case.find_by_id(99999).should == nil
      setup_attachment_attributes("Case", 99999)

      expect {
        post "/attachments",
             query_params.merge(attachment: @attachment_attributes).to_json,
             headers
      }.to_not change(Attachment, :count)
      expect_not_found_response
    end
  end
end
