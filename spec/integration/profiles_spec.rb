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
      profiles = results["profiles"]
      profiles.size.should == 2
      profiles.map{ |p| p["id"] }.any?{ |id| id.nil? }.should == false

      juan = profiles.detect{ |r| r["name"] == "Juan" }
      juana = profiles.detect{ |r| r["name"] == "Juana" }
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
      result = JSON.parse(response.body)["profile"]
      result["id"].should == juan.id
      result["name"].should == "Juan"
      result["birth"].should == "1975-05-28"
    end

    it "returns 404 if profile does not exist" do
      get "/profiles/does_not_exist"

      response.code.should == "404"
      result = JSON.parse(response.body)
      result["error"]["message"].should == "Not Found"
    end

    it "returns 400 bad request on absent client id"
  end

  describe "POST create" do
    it "creates a new profile" do
      attributes = { :name => "Juan", :birth => Date.parse("1975-05-28") }
      expect {
        post "/profiles", { :profile => attributes }
      }.to change(Profile, :count).by(1)
    end

    it "returns the created profile as JSON" do
      attributes = { :name => "Juan", :birth => Date.parse("1975-05-28") }

      post "/profiles", { :profile => attributes }

      response.code.should == "201"
      result = JSON.parse(response.body)["profile"]
      result["name"].should == "Juan"
      result["birth"].should == "1975-05-28"
    end
  end

  describe "PUT update" do
    it "updates an existing profile record" do
      profile = Profile.create!(
        name: "Juan",
        birth: Date.parse("1975-05-28")
      )

      attributes = { :name => "Juana", :birth => Date.parse("1977-08-12") }
      put "/profiles/#{profile.id}", { :profile => attributes }

      profile.reload
      profile.name.should == "Juana"
      profile.birth.to_s.should == Date.parse("1977-08-12").to_s
    end

    it "returns the updated profile as JSON" do
      profile = Profile.create!(
        name: "Juan",
        birth: Date.parse("1975-05-28")
      )

      attributes = { :name => "Juana", :birth => Date.parse("1977-08-12") }
      put "/profiles/#{profile.id}", { :profile => attributes }

      response.code.should == "200"
      result = JSON.parse(response.body)["profile"]
      result["name"].should == "Juana"
      result["birth"].should == "1977-08-12"
    end

    it "returns 404 if profile does not exist" do
      attributes = { :name => "Juana", :birth => Date.parse("1977-08-12") }
      put "/profiles/1", { :profile => attributes }

      response.code.should == "404"
      result = JSON.parse(response.body)
      result["error"]["message"].should == "Not Found"
    end
  end

end