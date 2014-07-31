require "spec_helper"

# TODO client id validation
describe "cases", type: :api do

  let(:valid_request_attributes) { { "client_id" => "healer_spec" } }

  describe "GET index" do
    before(:each) do
      @patient1 = FactoryGirl.create(:patient)
      @patient2 = FactoryGirl.create(:deceased_patient)
      @case1 = FactoryGirl.create(:case, patient: @patient1)
      @case2 = FactoryGirl.create(:case, patient: @patient2)
    end

    it "returns all records as JSON" do
      get "/cases", {}, valid_request_attributes

      response.code.should == "200"
      response_body = JSON.parse(response.body)
      response_records = response_body["cases"]
      response_records.size.should == 2
      response_records.map{ |c| c["id"] }.any?{ |id| id.nil? }.should == false

      response_record_1 = response_records.detect{ |c| c["id"] == @case1.id }
      response_record_2 = response_records.detect{ |c| c["id"] == @case2.id }

      PATIENT_ATTRIBUTES.each do |attr|
        response_record_1["patient"][attr].to_s.should == @patient1.send(attr).to_s
        response_record_2["patient"][attr].to_s.should == @patient2.send(attr).to_s
      end
    end
  end#index

  describe "GET show" do
    it "returns a single record as JSON" do
      patient = FactoryGirl.create(:patient)
      the_case = FactoryGirl.create(:case, patient: patient)

      get "/cases/#{the_case.id}", {}, valid_request_attributes

      response.code.should == "200"
      response_record = JSON.parse(response.body)["case"]
      CASE_ATTRIBUTES.each do |attr|
        response_record[attr].to_s.should == the_case.send(attr).to_s
      end
      PATIENT_ATTRIBUTES.each do |attr|
        response_record["patient"][attr].to_s.should == patient.send(attr).to_s
      end
    end

    it "returns 404 if there is no record for the case" do
      get "/cases/100"

      response.code.should == "404"
      response_body = JSON.parse(response.body)
      response_body["error"]["message"].should == "Not Found"
    end
  end#show

  describe "POST create" do
    context "when patient is posted as nested attribute" do
      it "creates a new persisted record for the case" do
        case_attributes = FactoryGirl.attributes_for(:case)
        patient_attributes = FactoryGirl.attributes_for(:patient)
        case_attributes[:patient] = patient_attributes

        expect {
          post "/cases", { case: case_attributes }
        }.to change(Case, :count).by(1)

        persisted_record = Case.last
        CASE_ATTRIBUTES.each do |attr|
          case_attributes[attr.to_sym].to_s.should == persisted_record.send(attr).to_s
        end
      end

      it "creates a new persisted record for the patient" do
        case_attributes = FactoryGirl.attributes_for(:case)
        patient_attributes = FactoryGirl.attributes_for(:patient)
        case_attributes[:patient] = patient_attributes

        expect {
          post "/cases", { case: case_attributes }
        }.to change(Patient, :count).by(1)

        new_patient = Patient.last
        PATIENT_ATTRIBUTES.each do |attr|
          patient_attributes[attr.to_sym].to_s.should == new_patient.send(attr).to_s
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
          case_attributes[:patient] = { name: "Changed #{original_patient_name}" }

          expect {
            post "/cases", { case: case_attributes }
          }.to change(Case, :count).by(1)

          @patient.reload.name.should == original_patient_name
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
      patient = FactoryGirl.create(:patient)
      case_record = FactoryGirl.create(:case,
        patient: patient,
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
  end#update

end