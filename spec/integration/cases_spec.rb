require "spec_helper"

describe "cases", type: :api do

  let(:query_params) { {} }
  let(:headers) { {
    "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Token.encode_credentials("ABCDEF0123456789")
  } }
  let(:headers_with_json_content_type) { headers.merge("Content-Type" => "application/json") }

  describe "GET index" do
    before(:each) do
      @patient_1 = FactoryGirl.create(:patient)
      @patient_2 = FactoryGirl.create(:deceased_patient)
      @persisted_1 = FactoryGirl.create(:case, patient: @patient_1)
      @persisted_2 = FactoryGirl.create(:case, patient: @patient_2)
    end

    it "returns 401 if authentication headers are not present" do
      get "/cases"

      expect_failed_authentication
    end

    it "returns all records as JSON" do
      get "/cases", query_params, headers

      response.code.should == "200"
      response_records = json["cases"]
      response_records.size.should == 2
      response_records.map{ |r| r["id"] }.any?{ |id| id.nil? }.should == false

      response_record_1 = response_records.detect{ |r| r["id"] == @persisted_1.id }
      response_record_2 = response_records.detect{ |r| r["id"] == @persisted_2.id }

      PATIENT_ATTRIBUTES.each do |attr|
        response_record_1["patient"][attr.to_s].to_s.should == @patient_1.send(attr).to_s
        response_record_2["patient"][attr.to_s].to_s.should == @patient_2.send(attr).to_s
      end
    end

    it "does not return deleted records" do
      delete "/cases/#{@persisted_2.id}", query_params, headers

      get "/cases", query_params, headers

      response.code.should == "200"
      response_records = json["cases"]
      response_records.size.should == 1

      response_records.map{ |r| r["id"] }.should_not include(@persisted_2.id)
    end

    it "filters by status" do
      @persisted_1.update_attributes!(status: "pending")

      get "/cases?status=pending", query_params, headers

      response.code.should == "200"
      response_records = json["cases"]
      response_records.size.should == 1

      response_record = response_records.first["patient"]

      response_record["id"].to_s.should == @persisted_1.id.to_s
    end

    it "does not return results for deleted records, even if asked" do
      @persisted_1.update_attributes!(status: "deleted")

      get "/cases?status=deleted", query_params, headers

      response.code.should == "200"
      response_records = json["cases"]
      response_records.size.should == 0
    end
  end#index

  describe "GET show" do
    before(:each) do
      @persisted_patient = FactoryGirl.create(:patient)
      @persisted_case = FactoryGirl.create(:case, patient: @persisted_patient)
    end

    it "returns 401 if authentication headers are not present" do
      get "/cases/#{@persisted_case.id}"

      expect_failed_authentication
    end

    it "returns a single persisted record as JSON" do
      get "/cases/#{@persisted_case.id}", query_params, headers

      response.code.should == "200"
      response_record = JSON.parse(response.body)["case"]
      CASE_ATTRIBUTES.each do |attr|
        response_record[attr.to_s].to_s.should == @persisted_case.send(attr).to_s
      end
      PATIENT_ATTRIBUTES.each do |attr|
        response_record["patient"][attr.to_s].to_s.should == @persisted_patient.send(attr).to_s
      end
    end

    it "returns pending cases" do
      @persisted_case.update_attributes!(status: "pending")

      get "/cases/#{@persisted_case.id}", query_params, headers

      response.code.should == "200"
      response_record = JSON.parse(response.body)["case"]
      response_record["id"].should == @persisted_case.id
    end

    it "returns 404 if there is no persisted record" do
      get "/cases/#{@persisted_case.id + 1}", query_params, headers

      expect_not_found_response
    end

    it "does not return status attribute" do
      get "/cases/#{@persisted_case.id}", query_params, headers

      response.code.should == "200"
      response_record = JSON.parse(response.body)["case"]
      response_record.keys.should_not include("status")
      response_record.keys.should_not include("active")
    end

    it "returns 404 if the record is deleted" do
      persisted_record = FactoryGirl.create(:deleted_case)

      get "/cases/#{persisted_record.id}", query_params, headers

      expect_not_found_response
    end

    it "returns 404 if the patient is deleted" do
      persisted_patient = FactoryGirl.create(:deleted_patient)
      persisted_record = FactoryGirl.create(:case, patient: persisted_patient)

      get "/cases/#{persisted_record.id}", query_params, headers

      expect_not_found_response
    end
  end#show

  describe "POST create" do
    it "returns 401 if authentication headers are not present" do
      post "/cases",
           { case: FactoryGirl.attributes_for(:case) }.to_json,
           "Content-Type" => "application/json"

      expect_failed_authentication
    end

    it "returns 400 if JSON content-type not specified"

    context "when patient is posted as nested attribute" do
      it "creates a new active persisted record for the case and returns JSON" do
        case_attributes = FactoryGirl.attributes_for(:case)
        patient_attributes = FactoryGirl.attributes_for(:patient)
        case_attributes[:patient] = patient_attributes

        expect {
          post "/cases",
               query_params.merge(case: case_attributes).to_json,
               headers_with_json_content_type
        }.to change(Case, :count).by(1)

        response.code.should == "201"

        response_record = JSON.parse(response.body)["case"]
        persisted_record = Case.last
        persisted_record.active?.should == true
        CASE_ATTRIBUTES.each do |attr|
          case_attributes[attr].to_s.should == persisted_record.send(attr).to_s
          response_record[attr.to_s].to_s.should == persisted_record.send(attr).to_s
        end
      end

      it "creates a new active persisted record for the patient" do
        case_attributes = FactoryGirl.attributes_for(:case)
        patient_attributes = FactoryGirl.attributes_for(:patient)
        case_attributes[:patient] = patient_attributes

        expect {
          post "/cases",
               query_params.merge(case: case_attributes).to_json,
               headers_with_json_content_type
        }.to change(Patient, :count).by(1)

        response_record = JSON.parse(response.body)["case"]["patient"]
        persisted_record = Patient.last
        persisted_record.active?.should == true
        PATIENT_ATTRIBUTES.each do |attr|
          patient_attributes[attr].to_s.should == persisted_record.send(attr).to_s
          response_record[attr.to_s].to_s.should == persisted_record.send(attr).to_s
        end
      end

      it "returns 400 if patient name is not supplied" do
        case_attributes = FactoryGirl.attributes_for(:case)
        patient_attributes = FactoryGirl.attributes_for(:patient)
        patient_attributes.delete(:name)
        case_attributes[:patient] = patient_attributes

        expect {
          post "/cases",
               query_params.merge(case: case_attributes).to_json,
               headers_with_json_content_type
        }.to_not change(Case, :count)

        response.code.should == "400"
        json["error"]["message"].should match(/name/i)
      end

      it "ignores status in request input" do
        case_attributes = FactoryGirl.attributes_for(:deleted_case)
        patient_attributes = FactoryGirl.attributes_for(:deleted_patient)
        case_attributes[:patient] = patient_attributes

        expect {
          post "/cases",
               query_params.merge(case: case_attributes).to_json,
               headers_with_json_content_type
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
          post "/cases",
               query_params.merge(case: case_attributes).to_json,
               headers_with_json_content_type
        }.to change(Case, :count).by(1)

        persisted_record = Case.last
        response_record = JSON.parse(response.body)["case"]["patient"]

        CASE_ATTRIBUTES.each do |attr|
          case_attributes[attr].to_s.should == persisted_record.send(attr).to_s
        end
        PATIENT_ATTRIBUTES.each do |attr|
          response_record[attr.to_s].to_s.should == @patient.send(attr).to_s
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
            post "/cases",
                 query_params.merge(case: case_attributes).to_json,
                 headers_with_json_content_type
          }.to change(Case, :count).by(1)

          @patient.reload
          @patient.name.should == original_patient_name
          @patient.active?.should == true
          persisted_record = Case.last
          CASE_ATTRIBUTES.each do |attr|
            case_attributes[attr].to_s.should == persisted_record.send(attr).to_s
          end
        end

        it "does not create a new patient" do
          case_attributes = FactoryGirl.attributes_for(:case)
          case_attributes[:patient_id] = @patient.id
          case_attributes[:patient] = { name: "New Patient Info" }

          expect {
            post "/cases",
                 query_params.merge(case: case_attributes).to_json,
                 headers_with_json_content_type
          }.to_not change(Patient, :count)
        end
      end

      it "returns 404 if patient is not found for patient_id" do
        case_attributes = FactoryGirl.attributes_for(:case)
        case_attributes[:patient_id] = 100
        case_attributes[:patient] = { name: "Patient Info" }

        post "/cases",
             query_params.merge(case: case_attributes).to_json,
             headers_with_json_content_type

        expect_not_found_response
      end
    end

    context "on unexpected input" do
      it "returns 400 on absent patient or patient id" do
        case_attributes = FactoryGirl.attributes_for(:case)

        post "/cases",
             query_params.merge(case: case_attributes).to_json,
             headers_with_json_content_type

        response.code.should == "400"
        json["error"]["message"].should match(/patient/i)
      end
    end
  end#create

  describe "PUT update" do
    it "returns 401 if authentication headers are not present" do
      persisted_record = FactoryGirl.create(:case)
      new_attributes = { anatomy: "hip" }

      put "/cases/#{persisted_record.id}",
          { case: new_attributes }.to_json,
          "Content-Type" => "application/json"

      expect_failed_authentication
    end

    it "returns 400 if JSON content-type not specified"

    it "updates an existing case record" do
      persisted_record = FactoryGirl.create(:case,
        anatomy: "knee",
        side: "left"
      )
      new_attributes = {
        anatomy: "hip",
        side: "right"
      }

      put "/cases/#{persisted_record.id}",
          query_params.merge(case: new_attributes).to_json,
          headers_with_json_content_type

      persisted_record.reload
      persisted_record.anatomy.should == "hip"
      persisted_record.side.should == "right"
    end

    it "does not update patient information" do
      patient = FactoryGirl.create(:patient)
      original_patient_name = patient.name
      persisted_record = FactoryGirl.create(:case,
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

      put "/cases/#{persisted_record.id}",
          query_params.merge(case: new_attributes).to_json,
          headers_with_json_content_type

      persisted_record.reload
      persisted_record.patient.reload.should == patient
      persisted_record.patient.name.should == original_patient_name
    end

    it "ignores status in request input" do
      persisted_record = FactoryGirl.create(:deleted_case)

      put "/cases/#{persisted_record.id}",
          query_params.merge(case: { status: "active" }).to_json,
          headers_with_json_content_type

      persisted_record.reload
      persisted_record.active?.should == false
    end

    it "returns 404 and does not update when attempting to update a deleted record" do
      persisted_record = FactoryGirl.create(:deleted_case, anatomy: "knee")
      new_attributes = { anatomy: "hip" }

      put "/cases/#{persisted_record.id}",
          query_params.merge(case: new_attributes).to_json,
          headers_with_json_content_type

      expect_not_found_response
      persisted_record.reload
      persisted_record.anatomy.should == "knee"
    end
  end#update

  describe "DELETE" do
    it "returns 401 if authentication headers are not present" do
      persisted_record = FactoryGirl.create(:case)

      delete "/cases/#{persisted_record.id}"

      expect_failed_authentication
    end

    it "soft-deletes an existing persisted record" do
      persisted_record = FactoryGirl.create(:case)

      delete "/cases/#{persisted_record.id}", query_params, headers

      response.code.should == "200"
      json["message"].should == "Deleted"

      persisted_record.reload.active?.should == false
    end

    it "returns 404 if persisted record does not exist" do
      delete "/cases/100", query_params, headers

      expect_not_found_response
    end

    it "returns 404 if record is already deleted" do
      persisted_record = FactoryGirl.create(:deleted_case)

      delete "/cases/#{persisted_record.id}", query_params, headers

      expect_not_found_response
    end
  end#delete

end