require "spec_helper"

# TODO client id validation

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

  end

  describe "GET show" do

    it "returns a single profile as JSON" do
      juan = Profile.create!(
        name: "Juan",
        birth: Date.parse("1975-05-28")
      )

      get "/profiles/#{juan.id}", {}, valid_attributes

      response.code.should == "200"
      result = JSON.parse(response.body)
      result["name"].should == "Juan"
      result["birth"].should == "1975-05-28"
    end

    it "returns 400 bad request on absent client id"

  end

end