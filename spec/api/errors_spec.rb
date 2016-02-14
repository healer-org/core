RSpec.describe "errors", type: :api do
  it "API handles 404 errors with JSON response" do
    get("/not/a/real/path")

    expect_not_found_response
  end
end
