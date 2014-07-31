require "spec_helper"

# TODO client id validation
describe "cases", type: :api do

  let(:valid_request_attributes) { { "client_id" => "healer_spec" } }

  describe "GET index" do
    before(:each) do
      @patient1 = FactoryGirl.create(:patient)
      @patient2 = FactoryGirl.create(:deceased_patient)
      @persisted_1 = FactoryGirl.create(:case, patient: @patient1)
      @persisted_2 = FactoryGirl.create(:case, patient: @patient2)
    end

    it "returns all records as JSON" do
      get "/cases", {}, valid_request_attributes

      response.code.should == "200"
      response_body = JSON.parse(response.body)
      response_records = response_body["cases"]
      response_records.size.should == 2
      response_records.map{ |r| r["id"] }.any?{ |id| id.nil? }.should == false

      response_record_1 = response_records.detect{ |r| r["id"] == @persisted_1.id }
      response_record_2 = response_records.detect{ |r| r["id"] == @persisted_2.id }

      PATIENT_ATTRIBUTES.each do |attr|
        response_record_1["patient"][attr].to_s.should == @patient1.send(attr).to_s
        response_record_2["patient"][attr].to_s.should == @patient2.send(attr).to_s
      end
    end

    it "does not return deleted records" do
      @persisted_2.delete!

      get "/cases", {}, valid_request_attributes

      response.code.should == "200"
      response_body = JSON.parse(response.body)
      response_records = response_body["cases"]
      response_records.size.should == 1

      response_record = response_records.first["patient"]

      PATIENT_ATTRIBUTES.each do |attr|
        response_record[attr].to_s.should == @patient1.send(attr).to_s
      end
    end
  end#index

  describe "GET show" do
    before(:each) do
      @persisted_patient = FactoryGirl.create(:patient)
      @persisted_case = FactoryGirl.create(:case, patient: @persisted_patient)
    end

    it "returns a single persisted record as JSON" do
      get "/cases/#{@persisted_case.id}", {}, valid_request_attributes

      response.code.should == "200"
      response_record = JSON.parse(response.body)["case"]
      CASE_ATTRIBUTES.each do |attr|
        response_record[attr].to_s.should == @persisted_case.send(attr).to_s
      end
      PATIENT_ATTRIBUTES.each do |attr|
        response_record["patient"][attr].to_s.should == @persisted_patient.send(attr).to_s
      end
    end

    it "returns 404 if there is no persisted record" do
      get "/cases/#{@persisted_case.id + 1}"

      response.code.should == "404"
      response_body = JSON.parse(response.body)
      response_body["error"]["message"].should == "Not Found"
    end

    it "does not return status attribute" do
      get "/cases/#{@persisted_case.id}", {}, valid_request_attributes

      response.code.should == "200"
      response_record = JSON.parse(response.body)["case"]
      response_record.keys.should_not include("status")
      response_record.keys.should_not include("active")
    end

    it "returns 404 if the record is deleted" do
      persisted_record = FactoryGirl.create(:deleted_case)

      get "/cases/#{persisted_record.id}", {}, valid_request_attributes

      response.code.should == "404"
      response_body = JSON.parse(response.body)
      response_body["error"]["message"].should == "Not Found"
    end
  end#show

  describe "POST create" do
    context "when patient is posted as nested attribute" do
      it "creates a new active persisted record for the case and returns JSON" do
        case_attributes = FactoryGirl.attributes_for(:case)
        patient_attributes = FactoryGirl.attributes_for(:patient)
        case_attributes[:patient] = patient_attributes

        expect {
          post "/cases", { case: case_attributes }
        }.to change(Case, :count).by(1)

        response.code.should == "201"

        response_record = JSON.parse(response.body)["case"]
        persisted_record = Case.last
        persisted_record.active?.should == true
        CASE_ATTRIBUTES.each do |attr|
          case_attributes[attr.to_sym].to_s.should == persisted_record.send(attr).to_s
          response_record[attr].to_s.should == persisted_record.send(attr).to_s
        end
      end

      it "creates a new active persisted record for the patient" do
        case_attributes = FactoryGirl.attributes_for(:case)
        patient_attributes = FactoryGirl.attributes_for(:patient)
        case_attributes[:patient] = patient_attributes

        expect {
          post "/cases", { case: case_attributes }
        }.to change(Patient, :count).by(1)

        response_record = JSON.parse(response.body)["case"]["patient"]
        persisted_record = Patient.last
        persisted_record.active?.should == true
        PATIENT_ATTRIBUTES.each do |attr|
          patient_attributes[attr.to_sym].to_s.should == persisted_record.send(attr).to_s
          response_record[attr].to_s.should == persisted_record.send(attr).to_s
        end
      end

      it "returns 400 if patient name is not supplied" do
        case_attributes = FactoryGirl.attributes_for(:case)
        patient_attributes = FactoryGirl.attributes_for(:patient)
        patient_attributes.delete(:name)
        case_attributes[:patient] = patient_attributes

        expect {
          post "/cases", { case: case_attributes }
        }.to_not change(Case, :count)

        response.code.should == "400"
        response_body = JSON.parse(response.body)
        response_body["error"]["message"].should match(/name/i)
      end

      it "ignores status in request input" do
        case_attributes = FactoryGirl.attributes_for(:deleted_case)
        patient_attributes = FactoryGirl.attributes_for(:deleted_patient)
        case_attributes[:patient] = patient_attributes

        expect {
          post "/cases", { case: case_attributes }
        }.to change(Case, :count).by(1)

        response.code.should == "201"
        persisted_case_record = Case.last
        persisted_patient_record = Patient.last
        persisted_case_record.active?.should == true
        persisted_patient_record.active?.should == true
      end
    end

    context "when patient_id is posted" do
      before(:each) do
        @patient = FactoryGirl.create(:patient)
      end

      it "creates a new persisted case associated to the patient" do
        case_attributes = FactoryGirl.attributes_for(:case)
        case_attributes[:patient_id] = @patient.id

        expect {
          post "/cases", { case: case_attributes }
        }.to change(Case, :count).by(1)

        persisted_record = Case.last
        response_record = JSON.parse(response.body)["case"]["patient"]

        CASE_ATTRIBUTES.each do |attr|
          case_attributes[attr.to_sym].to_s.should == persisted_record.send(attr).to_s
        end
        PATIENT_ATTRIBUTES.each do |attr|
          response_record[attr].to_s.should == @patient.send(attr).to_s
        end
      end

      context "and patient nested attributes are posted" do
        it "does not update the persisted patient with the posted attributes" do
          original_patient_name = @patient.name
          case_attributes = FactoryGirl.attributes_for(:case)
          case_attributes[:patient_id] = @patient.id
          case_attributes[:patient] = {
            name: "Changed #{original_patient_name}",
            status: "deleted"
          }

          expect {
            post "/cases", { case: case_attributes }
          }.to change(Case, :count).by(1)

          @patient.reload
          @patient.name.should == original_patient_name
          @patient.active?.should == true
          persisted_record = Case.last
          CASE_ATTRIBUTES.each do |attr|
            case_attributes[attr.to_sym].to_s.should == persisted_record.send(attr).to_s
          end
        end

        it "does not create a new patient" do
          case_attributes = FactoryGirl.attributes_for(:case)
          case_attributes[:patient_id] = @patient.id
          case_attributes[:patient] = { name: "New Patient Info" }

          expect {
            post "/cases", { case: case_attributes }
          }.to_not change(Patient, :count)
        end
      end

      it "returns 404 if patient is not found for patient_id" do
        case_attributes = FactoryGirl.attributes_for(:case)
        case_attributes[:patient_id] = 100
        case_attributes[:patient] = { name: "Patient Info" }

        post "/cases", { case: case_attributes }

        response.code.should == "404"
        response_body = JSON.parse(response.body)
        response_body["error"]["message"].should == "Not Found"
      end
    end

    context "on unexpected input" do
      it "returns 400 on absent patient or patient id" do
        case_attributes = FactoryGirl.attributes_for(:case)

        post "/cases", { case: case_attributes }

        response.code.should == "400"
        response_body = JSON.parse(response.body)
        response_body["error"]["message"].should match(/patient/i)
      end
    end
  end#create

  describe "PUT update" do
    it "updates an existing case record" do
      case_record = FactoryGirl.create(:case,
        anatomy: "knee",
        side: "left"
      )
      new_attributes = {
        anatomy: "hip",
        side: "right"
      }

      put "/cases/#{case_record.id}", { case: new_attributes }

      case_record.reload
      case_record.anatomy.should == "hip"
      case_record.side.should == "right"
    end

    it "does not update patient information" do
      patient = FactoryGirl.create(:patient)
      original_patient_name = patient.name
      case_record = FactoryGirl.create(:case,
        patient: patient,
        anatomy: "knee",
        side: "left"
      )
      new_attributes = {
        anatomy: "hip",
        side: "right",
        patient_id: patient.id,
        patient: {
          name: "New Patient Name"
        }
      }

      put "/cases/#{case_record.id}", { case: new_attributes }

      case_record.reload
      case_record.patient.reload.should == patient
      case_record.patient.name.should == original_patient_name
    end

    it "ignores status in request input" do
      persisted_record = FactoryGirl.create(:deleted_case)

      put "/cases/#{persisted_record.id}", { case: { status: "active" } }

      persisted_record.reload
      persisted_record.active?.should == false
    end
  end#update

  describe "DELETE" do
    it "soft-deletes an existing persisted record" do
      persisted_record = FactoryGirl.create(:case)

      delete "/cases/#{persisted_record.id}"

      response.code.should == "200"
      response_body = JSON.parse(response.body)
      response_body["message"].should == "Deleted"

      persisted_record.reload.active?.should == false
    end

    it "returns 404 if persisted record does not exist" do
      delete "/cases/100"

      response.code.should == "404"
      response_body = JSON.parse(response.body)
      response_body["error"]["message"].should == "Not Found"
    end
  end#delete

end