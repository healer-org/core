require "spec_helper"

# TODO client id validation

describe "patients", type: :api do

  let(:valid_attributes) { { "client_id" => "healer_spec" } }

  describe "GET index" do
    it "returns all patients as JSON" do
      profile1 = Profile.create!(
        name: "Juan",
        birth: Date.parse("1975-05-28")
      )
      profile2 = Profile.create!(
        name: "Juana",
        birth: Date.parse("1977-08-12")
      )
      patient1 = Patient.create!(
        profile_id: profile1.id,
        gender: "M"
      )
      patient2 = Patient.create!(
        profile_id: profile2.id,
        gender: "F",
        death: Date.parse("2014-07-04")
      )

      get "/patients", {}, valid_attributes

      response.code.should == "200"
      results = JSON.parse(response.body)
      patients = results["patients"]
      patients.size.should == 2
      patients.map{ |p| p["id"] }.any?{ |id| id.nil? }.should == false

      juan = patients.detect{ |p| p["id"] == profile1.id }
      juana = patients.detect{ |p| p["id"] == profile2.id }

      juan["name"].should == "Juan"
      juan["birth"].should == "1975-05-28"
      juan["death"].should be_nil
      juan["gender"].should == "M"

      juana["name"].should == "Juana"
      juana["birth"].should == "1977-08-12"
      juana["death"].should == "2014-07-04"
      juana["gender"].should == "F"
    end
  end

  describe "GET show" do
    it "returns a single patient as JSON" do
      profile = Profile.create!(
        name: "Juan",
        birth: Date.parse("1975-05-28")
      )
      patient = Patient.create!(
        profile_id: profile.id,
        gender: "M"
      )

      get "/patients/#{profile.id}", {}, valid_attributes

      response.code.should == "200"
      result = JSON.parse(response.body)["patient"]
      result["id"].should == profile.id
      result["name"].should == "Juan"
      result["birth"].should == "1975-05-28"
    end

    it "returns 404 if there is no patient record for the profile" do
      profile = Profile.create!(
        name: "Juan",
        birth: Date.parse("1975-05-28")
      )

      get "/patients/#{profile.id}"

      response.code.should == "404"
      result = JSON.parse(response.body)
      result["error"]["message"].should == "Not Found"
    end

    it "returns 404 if there is no profile record for the patient" do
      patient = Patient.create!(
        profile_id: 1,
        gender: "M"
      )

      get "/patients/1"

      response.code.should == "404"
      result = JSON.parse(response.body)
      result["error"]["message"].should == "Not Found"
    end

    it "returns 404 if patient does not exist" do
      get "/patients/does_not_exist"

      response.code.should == "404"
      result = JSON.parse(response.body)
      result["error"]["message"].should == "Not Found"
    end
  end

end