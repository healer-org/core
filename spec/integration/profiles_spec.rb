require "spec_helper"

describe "profiles", type: :api do

  let(:valid_attributes) { { "client_id" => "healer_spec" } }

  describe "GET index" do

    it "returns all profiles as JSON" do
      profile1 = Profile.create!(
        name: "Juan",
        birth: Date.parse("1975-05-28")
      )
      profile2 = Profile.create!(
        name: "Juana",
        birth: Date.parse("1977-08-12")
      )

      get "/profiles", {}, valid_attributes

      response.code.should == "200"
      results = JSON.parse(response.body)
      results.size.should == 2
      results.map{ |r| r["id"] }.any?{ |id| id.nil? }.should == false

      juan = results.detect{ |r| r["name"] == "Juan" }
      juana = results.detect{ |r| r["name"] == "Juana" }
      juan["birth"].should == "1975-05-28"
      juana["birth"].should == "1977-08-12"
    end

    it "returns 400 bad request on absent client id"
  end

end