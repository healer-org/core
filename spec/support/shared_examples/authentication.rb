RSpec.shared_examples "an authentication-protected #index endpoint" do
  it "returns 401 if authentication headers are not present" do
    get(endpoint_root_path)

    expect_failed_authentication
  end
end

RSpec.shared_examples "an authentication-protected #show endpoint" do
  it "returns 401 if authentication headers are not present" do
    get("#{endpoint_root_path}/1")

    expect_failed_authentication
  end
end

RSpec.shared_examples "an authentication-protected #create endpoint" do
  it "returns 401 if authentication headers are not present" do
    post(endpoint_root_path, {}.to_json, json_content_headers)

    expect_failed_authentication
  end
end

RSpec.shared_examples "an authentication-protected #update endpoint" do
  it "returns 401 if authentication headers are not present" do
    put("#{endpoint_root_path}/1", {}.to_json, json_content_headers)

    expect_failed_authentication
  end
end

RSpec.shared_examples "an authentication-protected #delete endpoint" do
  it "returns 401 if authentication headers are not present" do
    delete("#{endpoint_root_path}/1")

    expect_failed_authentication
  end
end
