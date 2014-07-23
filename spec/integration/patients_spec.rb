require "spec_helper"

# TODO client id validation
# TODO messaging & logging behavior
# TODO undelete functionality for administrator clients

describe "patients", type: :api do

  let(:valid_attributes) { { "client_id" => "healer_spec" } }

  describe "GET index" do
    before(:each) do
      @patient1 = Patient.create!(
        name: "Juan",
        birth: Date.parse("1975-05-28"),
        gender: "M",
      )
      @patient2 = Patient.create!(
        name: "Juana",
        birth: Date.parse("1977-08-12"),
        gender: "F",
        death: Date.parse("2014-07-04")
      )
    end

    it "returns all patients as JSON" do
      get "/patients", {}, valid_attributes

      response.code.should == "200"
      results = JSON.parse(response.body)
      patients = results["patients"]
      patients.size.should == 2
      patients.map{ |p| p["id"] }.any?{ |id| id.nil? }.should == false

      juan = patients.detect{ |p| p["id"] == @patient1.id }
      juana = patients.detect{ |p| p["id"] == @patient2.id }

      juan["name"].should == "Juan"
      juan["birth"].should == "1975-05-28"
      juan["death"].should be_nil
      juan["gender"].should == "M"

      juana["name"].should == "Juana"
      juana["birth"].should == "1977-08-12"
      juana["death"].should == "2014-07-04"
      juana["gender"].should == "F"
    end

    it "does not return deleted patients" do
      @patient2.delete!

      get "/patients", {}, valid_attributes

      response.code.should == "200"
      results = JSON.parse(response.body)
      patients = results["patients"]
      patients.size.should == 1

      juan = patients.first

      juan["name"].should == "Juan"
      juan["birth"].should == "1975-05-28"
      juan["death"].should be_nil
      juan["gender"].should == "M"
    end

    context "when showCases param is true" do
      it "returns cases as additional JSON" do
        case1 = Case.create!(
          patient_id: @patient1.id,
          anatomy: "hip",
          side: "left"
        )
        case2 = Case.create!(
          patient_id: @patient2.id,
          anatomy: "knee",
          side: "right"
        )

        get "/patients?showCases=true", {}, valid_attributes

        response.code.should == "200"
        results = JSON.parse(response.body)
        patients = results["patients"]
        patients.size.should == 2

        juan = patients.detect{ |p| p["id"] == @patient1.id }
        juana = patients.detect{ |p| p["id"] == @patient2.id }

        juan_case = juan["cases"].first
        juana_case = juana["cases"].first

        juan_case["anatomy"].should == "hip"
        juan_case["side"].should == "left"

        juana_case["anatomy"].should == "knee"
        juana_case["side"].should == "right"
      end
    end
  end#index

  describe "GET show" do
    before(:each) do
      @patient = Patient.create!(
        name: "Juan",
        birth: Date.parse("1975-05-28"),
        gender: "M"
      )
    end

    it "returns a single patient as JSON" do
      get "/patients/#{@patient.id}", {}, valid_attributes

      response.code.should == "200"
      result = JSON.parse(response.body)["patient"]
      result["id"].should == @patient.id
      result["name"].should == "Juan"
      result["birth"].should == "1975-05-28"
    end

    it "returns 404 if there is no record for the patient" do
      get "/patients/#{@patient.id + 1}"

      response.code.should == "404"
      result = JSON.parse(response.body)
      result["error"]["message"].should == "Not Found"
    end

    it "does not return status attribute" do
      get "/patients/#{@patient.id}", {}, valid_attributes

      response.code.should == "200"
      result = JSON.parse(response.body)["patient"]
      result.keys.should_not include("status")
      result.keys.should_not include("active")
    end

    it "returns 404 if the patient is deleted" do
      patient = Patient.create!(
        name: "Juan",
        status: "deleted"
      )

      get "/patients/#{patient.id}"

      response.code.should == "404"
      result = JSON.parse(response.body)
      result["error"]["message"].should == "Not Found"
    end

    context "when showCases param is true" do
      it "returns all cases as JSON" do
        case1 = Case.create!(
          patient_id: @patient.id,
          anatomy: "knee",
          side: "left"
        )
        case1 = Case.create!(
          patient_id: @patient.id,
          anatomy: "knee",
          side: "right"
        )

        get "/patients/#{@patient.id}?showCases=true", {}, valid_attributes

        response.code.should == "200"
        result = JSON.parse(response.body)["patient"]
        result["id"].should == @patient.id
        result["name"].should == "Juan"
        result["birth"].should == "1975-05-28"
        result["gender"].should == "M"
        cases = result["cases"]
        cases.map{ |c| c["anatomy"] }.uniq.should == ["knee"]
        cases.map{ |c| c["side"] }.should =~ ["left", "right"]
      end
    end
  end#show

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

    it "creates new patient as active" do
      post "/patients", { patient: { name: "Juan" } }

      response.code.should == "201"
      patient = Patient.last
      patient.active?.should == true
    end

    it "ignores status input" do
      attributes = {
        name: "Juan",
        status: "deleted"
      }

      post "/patients", { patient: attributes }

      response.code.should == "201"
      patient = Patient.last
      patient.active?.should == true
    end
  end#create

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

    it "ignores status input" do
      patient = Patient.create!(name: "Juan", status: "deleted")
      attributes = {
        name: "Juan Marco",
        status: "active"
      }

      put "/patients/#{patient.id}", { patient: attributes }

      patient.reload
      patient.name.should == "Juan Marco"
      patient.active?.should == false
    end
  end#update

  describe "DELETE" do
    it "soft-deletes an existing patient record" do
      patient = Patient.create!(
        name: "Juan",
        status: "active"
      )

      delete "/patients/#{patient.id}"

      response.code.should == "200"
      result = JSON.parse(response.body)
      result["message"].should == "Deleted"

      patient.reload
      patient.name.should == "Juan"
      patient.active?.should == false
    end

    it "returns 404 if patient does not exist" do
      delete "/patients/1"

      response.code.should == "404"
      result = JSON.parse(response.body)
      result["error"]["message"].should == "Not Found"
    end
  end#delete

end