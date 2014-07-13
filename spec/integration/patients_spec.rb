require "spec_helper"

# TODO client id validation

describe "patients", type: :api do

  let(:valid_attributes) { { "client_id" => "healer_spec" } }

  describe "GET index" do
    it "returns all patients as JSON" do
      patient1 = Patient.create!(
        name: "Juan",
        birth: Date.parse("1975-05-28"),
        gender: "M",
      )
      patient2 = Patient.create!(
        name: "Juana",
        birth: Date.parse("1977-08-12"),
        gender: "F",
        death: Date.parse("2014-07-04")
      )

      get "/patients", {}, valid_attributes

      response.code.should == "200"
      results = JSON.parse(response.body)
      patients = results["patients"]
      patients.size.should == 2
      patients.map{ |p| p["id"] }.any?{ |id| id.nil? }.should == false

      juan = patients.detect{ |p| p["id"] == patient1.id }
      juana = patients.detect{ |p| p["id"] == patient2.id }

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
      patient = Patient.create!(
        name: "Juan",
        birth: Date.parse("1975-05-28"),
        gender: "M"
      )

      get "/patients/#{patient.id}", {}, valid_attributes

      response.code.should == "200"
      result = JSON.parse(response.body)["patient"]
      result["id"].should == patient.id
      result["name"].should == "Juan"
      result["birth"].should == "1975-05-28"
    end

    it "returns 404 if there is no record for the patient" do
      get "/patients/1"

      response.code.should == "404"
      result = JSON.parse(response.body)
      result["error"]["message"].should == "Not Found"
    end
  end

  describe "POST create" do
    it "creates a new patient" do
      attributes = {
        name: "Juan",
        birth: Date.parse("1975-05-28"),
        gender: "M"
      }

      expect {
        post "/patients", { patient: attributes }
      }.to change(Patient, :count).by(1)
    end

    it "returns the created patient as JSON" do
      attributes = {
        name: "Juan",
        birth: Date.parse("1975-05-28"),
        gender: "M"
      }

      post "/patients", { patient: attributes }

      response.code.should == "201"
      result = JSON.parse(response.body)["patient"]
      result["name"].should == "Juan"
      result["birth"].should == "1975-05-28"
      result["gender"].should == "M"
    end

    it "returns 400 if name is not supplied" do
      attributes = {
        birth: Date.parse("1975-05-28"),
        gender: "M"
      }

      post "/patients", { patient: attributes }

      response.code.should == "400"
      result = JSON.parse(response.body)
      result["error"]["message"].should match(/name/i)
    end
  end

  describe "PUT update" do
    it "updates an existing patient record" do
      patient = Patient.create!(name: "Juan")
      attributes = {
        name: "Juan Marco",
        birth: Date.parse("1977-08-12"),
        gender: "M",
        death: Date.parse("2014-07-12")
      }

      put "/patients/#{patient.id}", { patient: attributes }

      patient.reload
      patient.name.should == "Juan Marco"
      patient.gender.should == "M"
      patient.birth.to_s.should == Date.parse("1977-08-12").to_s
      patient.death.to_s.should == Date.parse("2014-07-12").to_s
    end

    it "returns the updated patient as JSON" do
      patient = Patient.create!(
        name: "Juan",
        birth: Date.parse("1975-05-28")
      )

      attributes = {
        name: "Juana",
        birth: Date.parse("1977-08-12")
      }
      put "/patients/#{patient.id}", { patient: attributes }

      response.code.should == "200"
      result = JSON.parse(response.body)["patient"]
      result["name"].should == "Juana"
      result["birth"].should == "1977-08-12"
    end

    it "returns 404 if patient does not exist" do
      attributes = {
        name: "Juana",
        birth: Date.parse("1977-08-12")
      }
      put "/patients/1", { patient: attributes }

      response.code.should == "404"
      result = JSON.parse(response.body)
      result["error"]["message"].should == "Not Found"
    end
  end

end