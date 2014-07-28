require "spec_helper"

# TODO client id validation
# TODO messaging & logging behavior
# TODO undelete functionality for administrator clients
VALID_PATIENT_ATTRIBUTES = %w(id name birth death gender)
VALID_CASE_ATTRIBUTES = %w(anatomy side)

describe "patients", type: :api do

  let(:valid_PATIENT_attributes) { { "client_id" => "healer_spec" } }

  describe "GET index" do
    before(:each) do
      @patient1 = FactoryGirl.create(:patient)
      @patient2 = FactoryGirl.create(:patient)

      @patient1.name.should_not == @patient2.name
    end

    it "returns all patients as JSON" do
      get "/patients", {}, valid_PATIENT_attributes

      response.code.should == "200"
      results = JSON.parse(response.body)
      patients = results["patients"]
      patients.size.should == 2
      patients.map{ |p| p["id"] }.any?{ |id| id.nil? }.should == false

      patient1 = patients.detect{ |p| p["id"] == @patient1.id }
      patient2 = patients.detect{ |p| p["id"] == @patient2.id }

      VALID_PATIENT_ATTRIBUTES.each do |attr|
        patient1[attr].to_s.should == @patient1.send(attr).to_s
        patient2[attr].to_s.should == @patient2.send(attr).to_s
      end
    end

    it "does not return deleted patients" do
      @patient2.delete!

      get "/patients", {}, valid_PATIENT_attributes

      response.code.should == "200"
      results = JSON.parse(response.body)
      patients = results["patients"]
      patients.size.should == 1

      patient = patients.first

      VALID_PATIENT_ATTRIBUTES.each do |attr|
        patient[attr].to_s.should == @patient1.send(attr).to_s
      end
    end

    context "when showCases param is true" do
      it "returns cases as additional JSON" do
        case1 = FactoryGirl.create(:case, patient: @patient1)
        case2 = FactoryGirl.create(:case, patient: @patient2)

        get "/patients?showCases=true", {}, valid_PATIENT_attributes

        response.code.should == "200"
        results = JSON.parse(response.body)
        patients = results["patients"]
        patients.size.should == 2

        patient1 = patients.detect{ |p| p["id"] == @patient1.id }
        patient2 = patients.detect{ |p| p["id"] == @patient2.id }

        case1_result = patient1["cases"].first
        case2_result = patient2["cases"].first

        VALID_CASE_ATTRIBUTES.each do |attr|
          case1_result[attr].to_s.should == case1.send(attr).to_s
          case2_result[attr].to_s.should == case2.send(attr).to_s
        end
      end
    end
  end#index

  describe "GET show" do
    before(:each) do
      @patient = FactoryGirl.create(:patient)
    end

    it "returns a single patient as JSON" do
      get "/patients/#{@patient.id}", {}, valid_PATIENT_attributes

      response.code.should == "200"
      result = JSON.parse(response.body)["patient"]
      result["id"].should == @patient.id
      result["name"].should == @patient.name
      result["birth"].to_s.should == @patient.birth.to_s
    end

    it "returns 404 if there is no record for the patient" do
      get "/patients/#{@patient.id + 1}"

      response.code.should == "404"
      result = JSON.parse(response.body)
      result["error"]["message"].should == "Not Found"
    end

    it "does not return status attribute" do
      get "/patients/#{@patient.id}", {}, valid_PATIENT_attributes

      response.code.should == "200"
      result = JSON.parse(response.body)["patient"]
      result.keys.should_not include("status")
      result.keys.should_not include("active")
    end

    it "returns 404 if the patient is deleted" do
      patient = FactoryGirl.create(:deleted_patient)

      get "/patients/#{patient.id}"

      response.code.should == "404"
      result = JSON.parse(response.body)
      result["error"]["message"].should == "Not Found"
    end

    context "when showCases param is true" do
      it "returns all cases as JSON" do
        case1 = FactoryGirl.create(:case, patient: @patient)
        case2 = FactoryGirl.create(:case, patient: @patient)

        get "/patients/#{@patient.id}?showCases=true", {}, valid_PATIENT_attributes

        response.code.should == "200"
        result = JSON.parse(response.body)["patient"]

        VALID_PATIENT_ATTRIBUTES.each do |attr|
          result[attr].to_s.should == @patient.send(attr).to_s
        end

        cases = result["cases"]
        cases.size.should == 2
        VALID_CASE_ATTRIBUTES.each do |attr|
          cases[0][attr].to_s.should == case1.send(attr).to_s
          cases[1][attr].to_s.should == case2.send(attr).to_s
        end
      end
    end
  end#show

  describe "POST create" do
    it "creates a new patient" do
      attributes = FactoryGirl.attributes_for(:patient)

      expect {
        post "/patients", { patient: attributes }
      }.to change(Patient, :count).by(1)
    end

    it "returns the created patient as JSON" do
      attributes = FactoryGirl.attributes_for(:patient)

      post "/patients", { patient: attributes }

      response.code.should == "201"

      result = JSON.parse(response.body)["patient"]
      new_record = Patient.last
      VALID_PATIENT_ATTRIBUTES.each do |attr|
        result[attr].to_s.should == new_record.send(attr).to_s
      end
    end

    it "returns 400 if name is not supplied" do
      attributes = FactoryGirl.attributes_for(:patient)
      attributes.delete(:name)

      post "/patients", { patient: attributes }

      response.code.should == "400"
      result = JSON.parse(response.body)
      result["error"]["message"].should match(/name/i)
    end

    it "creates new patient as active" do
      attributes = FactoryGirl.attributes_for(:patient)
      attributes.delete(:status)

      post "/patients", { patient: attributes }

      response.code.should == "201"
      new_record = Patient.last
      new_record.active?.should == true
    end

    it "ignores status input" do
      attributes = FactoryGirl.attributes_for(:deleted_patient)

      post "/patients", { patient: attributes }

      response.code.should == "201"
      patient = Patient.last
      patient.active?.should == true
    end
  end#create

  describe "PUT update" do
    it "updates an existing patient record" do
      patient = FactoryGirl.create(:patient)
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
      patient = FactoryGirl.create(:patient)
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
      patient = FactoryGirl.create(:deleted_patient)
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
      patient = FactoryGirl.create(:patient)

      delete "/patients/#{patient.id}"

      response.code.should == "200"
      result = JSON.parse(response.body)
      result["message"].should == "Deleted"

      patient.reload.active?.should == false
    end

    it "returns 404 if patient does not exist" do
      delete "/patients/1"

      response.code.should == "404"
      result = JSON.parse(response.body)
      result["error"]["message"].should == "Not Found"
    end
  end#delete

end