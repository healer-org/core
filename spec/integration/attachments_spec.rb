require "spec_helper"

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

  end
end
