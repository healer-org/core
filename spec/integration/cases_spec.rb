require "spec_helper"

describe "cases", type: :api do
  fixtures :cases, :patients

  let(:query_params) { {} }

  describe "GET index" do
    let(:headers) { token_auth_header }

    it "returns 401 if authentication headers are not present" do
      get "/cases"

      expect_failed_authentication
    end

    it "returns all records as JSON" do
      persisted_1 = cases(:fernando_left_hip)
      persisted_2 = cases(:silvia_right_foot)
      persisted_3 = cases(:silvia_left_foot)
      patient_1 = persisted_1.patient
      patient_2 = persisted_2.patient

      get "/cases", query_params, headers

      response.code.should == "200"
      response_records = json["cases"]

      response_ids_for(response_records).any?{ |id| id.nil? }.should == false

      response_record_1 = pluck_response_record(response_records, persisted_1.id)
      response_record_2 = pluck_response_record(response_records, persisted_2.id)
      response_record_3 = pluck_response_record(response_records, persisted_3.id)

      patient_response_matches?(response_record_1["patient"], patient_1).should == true
      patient_response_matches?(response_record_2["patient"], patient_2).should == true
      patient_response_matches?(response_record_3["patient"], patient_2).should == true
    end

    it "does not return deleted records" do
      deleted_case = cases(:fernando_deleted_right_knee)

      get "/cases", query_params, headers

      response.code.should == "200"
      response_ids_for(json["cases"]).should_not include(deleted_case.id)
    end

    it "filters by status" do
      persisted_1 = cases(:fernando_left_hip)
      persisted_2 = cases(:silvia_right_foot)
      persisted_1.update_attributes!(status: "pending")

      get "/cases?status=pending", query_params, headers

      response_ids = response_ids_for(json["cases"])

      response.code.should == "200"
      response_ids.should include(persisted_1.id)
      response_ids.should_not include(persisted_2.id)
    end

    it "does not return results for deleted records, even if asked" do
      persisted_1 = cases(:fernando_left_hip)
      persisted_2 = cases(:silvia_right_foot)
      persisted_1.update_attributes!(status: "deleted")

      get "/cases?status=deleted", query_params, headers

      response_ids = response_ids_for(json["cases"])

      response.code.should == "200"
      response_ids.should_not include(persisted_1.id)
    end

    it "does not include attachments in the output" do
      persisted = cases(:fernando_left_hip)
      attachment = Attachment.create!(
        record: persisted,
        document: fixture_file_upload("#{Rails.root}/spec/attachments/1x1.png", "image/png")
      )
      attachment.update_attributes!(record: persisted)

      get "/cases", query_params, headers

      response.code.should == "200"
      response_records = json["cases"]

      response_record = pluck_response_record(response_records, persisted.id)
      response_record.keys.should_not include("attachments")
    end

    it "returns attachments in JSON payload when show_attachments param is true" do
      persisted = cases(:fernando_left_hip)
      attachment = Attachment.create!(
        record: persisted,
        document: fixture_file_upload("#{Rails.root}/spec/attachments/1x1.png", "image/png")
      )
      attachment.update_attributes!(record: persisted)
      Attachment.count.should == 1

      get "/cases", query_params.merge(show_attachments: true), headers

      response.code.should == "200"
      response_records = json["cases"]

      response_record = pluck_response_record(response_records, persisted.id)
      response_record["attachments"].size.should == 1
      returned_attachment = response_record["attachments"].first
      returned_attachment.keys.should =~ ([:id] + ATTACHMENT_ATTRIBUTES).map{ |k| k.to_s.camelize(:lower) }
      attachment_response_matches?(returned_attachment, attachment).should == true
    end
  end#index

  describe "GET show" do
    let(:headers) { token_auth_header }

    it "returns 401 if authentication headers are not present" do
      persisted_case = cases(:fernando_left_hip)

      get "/cases/#{persisted_case.id}"

      expect_failed_authentication
    end

    it "returns a single persisted record as JSON" do
      persisted_case = cases(:fernando_left_hip)
      persisted_patient = persisted_case.patient

      get "/cases/#{persisted_case.id}", query_params, headers

      response.code.should == "200"
      response_record = json["case"]
      case_response_matches?(json["case"], persisted_case).should == true
      patient_response_matches?(json["case"]["patient"], persisted_patient).should == true
    end

    it "returns pending cases" do
      persisted_case = cases(:fernando_left_hip)
      persisted_case.update_attributes!(status: "pending")

      get "/cases/#{persisted_case.id}", query_params, headers

      response.code.should == "200"
      response_record = json["case"]
      response_record["id"].should == persisted_case.id
    end

    it "returns 404 if there is no persisted record" do
      persisted_case = cases(:fernando_left_hip)

      get "/cases/#{persisted_case.id + 1}", query_params, headers

      expect_not_found_response
    end

    it "does not return status attribute" do
      persisted_case = cases(:fernando_left_hip)

      get "/cases/#{persisted_case.id}", query_params, headers

      response.code.should == "200"
      response_record = json["case"]
      response_record.keys.should_not include("status")
      response_record.keys.should_not include("active")
    end

    it "does not include attachments in the output" do
      persisted = cases(:fernando_left_hip)
      attachment = Attachment.create!(
        record: persisted,
        document: fixture_file_upload("#{Rails.root}/spec/attachments/1x1.png", "image/png")
      )

      get "/cases/#{persisted.id}", query_params, headers

      response.code.should == "200"
      response_records = json["cases"]

      response.code.should == "200"
      response_record = json["case"]
      response_record.keys.should_not include("attachments")
    end

    it "returns attachments in JSON payload when show_attachments param is true" do
      persisted = cases(:fernando_left_hip)
      attachment = Attachment.create!(
        record: persisted,
        document: fixture_file_upload("#{Rails.root}/spec/attachments/1x1.png", "image/png")
      )

      get "/cases/#{persisted.id}", query_params.merge(show_attachments: true), headers

      response.code.should == "200"
      response_record = json["case"]
      response_record["attachments"].size.should == 1
      returned_attachment = response_record["attachments"].first
      returned_attachment.keys.should =~ ([:id] + ATTACHMENT_ATTRIBUTES).map{ |k| k.to_s.camelize(:lower) }
      attachment_response_matches?(returned_attachment, attachment).should == true
    end

    it "returns 404 if the record is deleted" do
      persisted_record = cases(:fernando_deleted_right_knee)

      get "/cases/#{persisted_record.id}", query_params, headers

      expect_not_found_response
    end

    it "returns 404 if the patient is deleted" do
      persisted_record = cases(:deleted_patient_active_left_hip)

      get "/cases/#{persisted_record.id}", query_params, headers

      expect_not_found_response
    end
  end#show

  describe "POST create" do
    let(:headers) { token_auth_header.merge(json_content_header) }

    it "returns 401 if authentication headers are not present" do
      attributes = cases(:fernando_left_hip).attributes.dup

      post "/cases",
           case: attributes.to_json,
           "Content-Type" => "application/json"

      expect_failed_authentication
    end

    it "returns 400 if JSON content-type not specified"

    context "when patient is posted as nested attribute" do
      it "creates a new active persisted record for the case and returns JSON" do
        a_case = cases(:fernando_left_hip)
        case_attributes = a_case.attributes.dup.symbolize_keys
        case_attributes[:patient] = a_case.patient.attributes.dup.symbolize_keys
        case_attributes.delete(:patient_id)
        a_case.patient.destroy
        a_case.destroy

        expect {
          post "/cases",
               query_params.merge(case: case_attributes).to_json,
               headers
        }.to change(Case, :count).by(1)

        response.code.should == "201"

        response_record = json["case"]
        persisted_record = Case.last
        persisted_record.active?.should == true
        CASE_ATTRIBUTES.each do |attr|
          case_attributes[attr].to_s.should == persisted_record.send(attr).to_s
        end
        case_response_matches?(response_record, persisted_record).should == true
      end

      it "creates a new active persisted record for the patient" do
        a_case = cases(:fernando_left_hip)
        case_attributes = a_case.attributes.dup.symbolize_keys
        patient_attributes = a_case.patient.attributes.dup.symbolize_keys
        case_attributes[:patient] = patient_attributes
        case_attributes.delete(:patient_id)
        a_case.patient.destroy
        a_case.destroy

        expect {
          post "/cases",
               query_params.merge(case: case_attributes).to_json,
               headers
        }.to change(Patient, :count).by(1)

        persisted_record = Patient.last
        persisted_record.active?.should == true

        patient_response_matches?(json["case"]["patient"], persisted_record).should == true
        PATIENT_ATTRIBUTES.each do |attr|
          patient_attributes[attr].to_s.should == persisted_record.send(attr).to_s
        end
      end

      it "returns 400 if patient name is not supplied" do
        a_case = cases(:fernando_left_hip)
        case_attributes = a_case.attributes.dup.symbolize_keys
        patient_attributes = a_case.patient.attributes.dup.symbolize_keys
        patient_attributes.delete(:name)
        case_attributes[:patient] = patient_attributes
        case_attributes.delete(:patient_id)
        a_case.patient.destroy
        a_case.destroy

        expect {
          post "/cases",
               query_params.merge(case: case_attributes).to_json,
               headers
        }.to_not change(Case, :count)

        response.code.should == "400"
        json["error"]["message"].should match(/name/i)
      end

      it "creates new cases as active, regardless of status input" do
        a_case = cases(:fernando_left_hip)
        case_attributes = a_case.attributes.dup.symbolize_keys
        patient_attributes = a_case.patient.attributes.dup.symbolize_keys
        case_attributes[:status] = "deleted"
        patient_attributes[:status] = "deleted"
        case_attributes[:patient] = patient_attributes
        case_attributes.delete(:patient_id)
        a_case.patient.destroy
        a_case.destroy

        expect {
          post "/cases",
               query_params.merge(case: case_attributes).to_json,
               headers
        }.to change(Case, :count).by(1)

        response.code.should == "201"
        persisted_case_record = Case.last
        persisted_patient_record = Patient.last
        persisted_case_record.active?.should == true
        persisted_patient_record.active?.should == true
      end
    end

    context "when patient_id is posted" do
      it "creates a new persisted case associated to the patient" do
        patient = patients(:silvia)
        case_attributes = cases(:fernando_left_hip).attributes.dup.symbolize_keys
        case_attributes[:patient_id] = patient.id

        expect {
          post "/cases",
               query_params.merge(case: case_attributes).to_json,
               headers
        }.to change(Case, :count).by(1)

        response_record = json["case"]["patient"]
        persisted_record = Case.last

        CASE_ATTRIBUTES.each do |attr|
          case_attributes[attr].to_s.should == persisted_record.send(attr).to_s
        end
        case_response_matches?(json["case"], persisted_record).should == true
        patient_response_matches?(json["case"]["patient"], patient).should == true
      end

      context "and patient nested attributes are posted" do
        it "does not update the persisted patient with the posted attributes" do
          patient = patients(:silvia)
          original_patient_name = patient.name
          case_attributes = cases(:fernando_left_hip).attributes.dup.symbolize_keys
          case_attributes[:patient_id] = patient.id
          case_attributes[:patient] = {
            name: "Changed #{original_patient_name}",
            status: "deleted"
          }

          expect {
            post "/cases",
                 query_params.merge(case: case_attributes).to_json,
                 headers
          }.to change(Case, :count).by(1)

          patient.reload
          persisted_record = Case.last

          CASE_ATTRIBUTES.each do |attr|
            case_attributes[attr].to_s.should == persisted_record.send(attr).to_s
          end
          case_response_matches?(json["case"], persisted_record).should == true
          patient.name.should == original_patient_name
          patient.active?.should == true
        end

        it "does not create a new patient" do
          patient = patients(:silvia)
          case_attributes = cases(:fernando_left_hip).attributes.dup.symbolize_keys
          case_attributes[:patient_id] = patient.id
          case_attributes[:patient] = { name: "New Patient Info" }

          expect {
            post "/cases",
                 query_params.merge(case: case_attributes).to_json,
                 headers
          }.to_not change(Patient, :count)
        end
      end

      it "returns 404 if patient is not found for patient_id" do
        Patient.find_by_id(100).should be_nil
        case_attributes = cases(:fernando_left_hip).attributes.dup.symbolize_keys
        case_attributes[:patient_id] = 100
        case_attributes[:patient] = { name: "Patient Info" }

        post "/cases",
             query_params.merge(case: case_attributes).to_json,
             headers

        expect_not_found_response
      end
    end

    context "on unexpected input" do
      it "returns 400 on absent patient or patient id" do
        case_attributes = cases(:fernando_left_hip).attributes.dup.symbolize_keys
        case_attributes.delete(:patient_id)

        post "/cases",
             query_params.merge(case: case_attributes).to_json,
             headers

        response.code.should == "400"
        json["error"]["message"].should match(/patient/i)
      end
    end
  end#create

  describe "PUT update" do
    let(:headers) { token_auth_header.merge(json_content_header) }

    it "returns 401 if authentication headers are not present" do
      persisted_record = cases(:fernando_left_hip)

      new_attributes = { anatomy: "hip" }

      put "/cases/#{persisted_record.id}",
          { case: new_attributes }.to_json,
          json_content_header

      expect_failed_authentication
    end

    it "returns 400 if JSON content-type not specified"

    it "updates an existing case record" do
      persisted_record = cases(:fernando_left_hip)
      new_attributes = {
        anatomy: "knee",
        side: "right"
      }

      put "/cases/#{persisted_record.id}",
          query_params.merge(case: new_attributes).to_json,
          headers

      persisted_record.reload
      persisted_record.anatomy.should == "knee"
      persisted_record.side.should == "right"
    end

    it "does not update patient information" do
      persisted_record = cases(:fernando_left_hip)
      patient = persisted_record.patient
      original_patient_name = patient.name
      new_attributes = {
        anatomy: "knee",
        side: "right",
        patient_id: patient.id,
        patient: {
          name: "New Patient Name"
        }
      }

      put "/cases/#{persisted_record.id}",
          query_params.merge(case: new_attributes).to_json,
          headers

      persisted_record.reload
      persisted_record.patient.reload.should == patient
      persisted_record.patient.name.should == original_patient_name
    end

    it "ignores status in request input" do
      persisted_record = cases(:fernando_deleted_right_knee)

      put "/cases/#{persisted_record.id}",
          query_params.merge(case: { status: "active" }).to_json,
          headers

      persisted_record.reload
      persisted_record.active?.should == false
    end

    it "returns 404 and does not update when attempting to update a deleted record" do
      persisted_record = cases(:fernando_deleted_right_knee)
      new_attributes = { anatomy: "hip" }

      put "/cases/#{persisted_record.id}",
          query_params.merge(case: new_attributes).to_json,
          headers

      expect_not_found_response
      persisted_record.reload
      persisted_record.anatomy.should == "hip"
    end
  end#update

  describe "DELETE" do
    let(:headers) { token_auth_header }

    it "returns 401 if authentication headers are not present" do
      persisted_record = cases(:fernando_left_hip)

      delete "/cases/#{persisted_record.id}"

      expect_failed_authentication
    end

    it "soft-deletes an existing persisted record" do
      persisted_record = cases(:fernando_left_hip)

      delete "/cases/#{persisted_record.id}", query_params, headers

      response.code.should == "200"
      json["message"].should == "Deleted"

      persisted_record.reload.active?.should == false
    end

    it "returns 404 if persisted record does not exist" do
      Case.find_by_id(100).should be_nil

      delete "/cases/100", query_params, headers

      expect_not_found_response
    end

    it "returns 404 if record is already deleted" do
      persisted_record = cases(:fernando_deleted_right_knee)

      delete "/cases/#{persisted_record.id}", query_params, headers

      expect_not_found_response
    end
  end#delete

end