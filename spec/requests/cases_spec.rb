# frozen_string_literal: true

RSpec.describe "cases", type: :request do
  fixtures :cases, :patients, :procedures

  let(:query_params) { {} }
  let(:endpoint_root_path) { "/cases" }
  let(:headers) { default_headers }

  def uploaded_file
    extend ActionDispatch::TestProcess
    fixture_file_upload("../attachments/1x1.png", "image/png")
  end

  def response_records
    json["cases"]
  end

  def response_record
    json["case"]
  end

  describe "GET index" do
    let(:path) { endpoint_root_path }
    let(:valid_procedure_data) do
      {
        date: Date.today,
        type: "a_procedure",
        version: "v1",
        providers: { "doc_1" => { role: :primary } }
      }
    end

    it_behaves_like "an endpoint that supports JSON, form, and text exchange", :get

    it "returns all records as JSON" do
      persisted_1 = cases(:fernando_left_hip)
      persisted_2 = cases(:silvia_right_foot)
      persisted_3 = cases(:silvia_left_foot)
      patient_1 = persisted_1.patient
      patient_2 = persisted_2.patient

      get(path, params: query_params, headers: headers)

      expect(response).to have_http_status(:ok)
      expect(response_ids_for(response_records).any?(&:nil?)).to eq(false)

      response_record_1 = pluck_response_record(response_records, persisted_1.id)
      response_record_2 = pluck_response_record(response_records, persisted_2.id)
      response_record_3 = pluck_response_record(response_records, persisted_3.id)

      expect(
        patient_response_matches?(response_record_1["patient"], patient_1)
      ).to eq(true)
      expect(
        patient_response_matches?(response_record_2["patient"], patient_2)
      ).to eq(true)
      expect(
        patient_response_matches?(response_record_3["patient"], patient_2)
      ).to eq(true)
    end

    it "does not return deleted records" do
      deleted_case = cases(:fernando_deleted_right_knee)

      get(path, params: query_params, headers: headers)

      expect(response).to have_http_status(:ok)
      expect(response_ids_for(json["cases"])).not_to include(deleted_case.id)
    end

    it "filters by status" do
      persisted_1 = cases(:fernando_left_hip)
      persisted_2 = cases(:silvia_right_foot)
      persisted_1.update_attributes!(status: "pending")

      get(path, params: query_params.merge(status: "pending"), headers: headers)

      response_ids = response_ids_for(json["cases"])

      expect(response).to have_http_status(:ok)
      expect(response_ids).to include(persisted_1.id)
      expect(response_ids).not_to include(persisted_2.id)
    end

    it "does not return results for deleted records, even if asked" do
      persisted_1 = cases(:fernando_left_hip)
      persisted_1.update_attributes!(status: "deleted")

      get(path, params: query_params.merge(status: "deleted"), headers: headers)

      response_ids = response_ids_for(json["cases"])

      expect(response).to have_http_status(:ok)
      expect(response_ids).not_to include(persisted_1.id)
    end

    it "does not include attachments in the output" do
      persisted = cases(:fernando_left_hip)
      Attachment.create!(
        record: persisted,
        document: uploaded_file
      )

      get(path, params: query_params, headers: headers)

      expect(response).to have_http_status(:ok)

      response_record = pluck_response_record(response_records, persisted.id)
      expect(response_record.keys).not_to include("attachments")
    end

    it "does not include procedures in the output" do
      persisted = cases(:fernando_left_hip)
      Procedure.create!(case: persisted, data: valid_procedure_data)

      get(path, params: query_params, headers: headers)

      expect(response).to have_http_status(:ok)

      response_record = pluck_response_record(response_records, persisted.id)
      expect(response_record.keys).not_to include("procedures")
    end

    it "returns attachments in JSON payload when showAttachments param is true" do
      persisted = cases(:fernando_left_hip)
      attachment = Attachment.create!(
        record: persisted,
        document: uploaded_file
      )

      get(path, params: query_params.merge(showAttachments: true), headers: headers)

      expect(response).to have_http_status(:ok)

      response_record = pluck_response_record(response_records, persisted.id)
      expect(response_record["attachments"].size).to eq(1)
      returned_attachment = response_record["attachments"].first
      expect(returned_attachment.keys).to match_array(
        ([:id] + ATTACHMENT_ATTRIBUTES).map { |k| k.to_s.camelize(:lower) }
      )
      expect(
        attachment_response_matches?(returned_attachment, attachment)
      ).to eq(true)
    end

    it "returns procedures in JSON payload when showProcedures param is true" do
      persisted = cases(:silvia_right_foot)
      expect(persisted.procedures.size).to eq(0)
      procedure = Procedure.create!(case: persisted, data: valid_procedure_data)

      get(path, params: query_params.merge(showProcedures: true), headers: headers)

      expect(response).to have_http_status(:ok)

      response_record = pluck_response_record(response_records, persisted.id)
      expect(response_record["procedures"].size).to eq(1)
      returned_procedure = response_record["procedures"].first
      expect(returned_procedure["id"]).to eq(procedure.id)
    end
  end

  describe "GET show" do
    let(:persisted_record) { cases(:fernando_left_hip) }
    let(:path) { "#{endpoint_root_path}/#{persisted_record.id}" }

    it_behaves_like "an endpoint that supports JSON, form, and text exchange", :get

    it "returns a single persisted record as JSON" do
      persisted_patient = persisted_record.patient

      get(path, params: query_params, headers: headers)

      expect(response).to have_http_status(:ok)
      expect(case_response_matches?(json["case"], persisted_record)).to eq(true)
      expect(patient_response_matches?(json["case"]["patient"], persisted_patient)).to eq(true)
    end

    it "returns pending cases" do
      persisted_record.update_attributes!(status: "pending")

      get(path, params: query_params, headers: headers)

      expect(response).to have_http_status(:ok)
      expect(response_record["id"]).to eq(persisted_record.id)
    end

    it "returns 404 if there is no persisted record" do
      path = "/patients/#{persisted_record.id + 1}"

      get(path, params: query_params, headers: headers)

      expect(response).to have_http_status(:not_found)
    end

    it "does not return status attribute" do
      get(path, params: query_params, headers: headers)

      expect(response).to have_http_status(:ok)
      expect(response_record.keys).not_to include("status")
      expect(response_record.keys).not_to include("active")
    end

    it "does not include attachments in the output" do
      Attachment.create!(
        record: persisted_record,
        document: uploaded_file
      )

      get(path, params: query_params, headers: headers)

      expect(response).to have_http_status(:ok)
      expect(response_record.keys).not_to include("attachments")
    end

    it "returns attachments in JSON payload when showAttachments param is true" do
      attachment = Attachment.create!(
        record: persisted_record,
        document: uploaded_file
      )

      get(path, params: query_params.merge(showAttachments: true), headers: headers)

      expect(response).to have_http_status(:ok)
      expect(response_record["attachments"].size).to eq(1)
      returned_attachment = response_record["attachments"].first
      expect(returned_attachment.keys).to match_array(
        ([:id] + ATTACHMENT_ATTRIBUTES).map { |k| k.to_s.camelize(:lower) }
      )
      expect(
        attachment_response_matches?(returned_attachment, attachment)
      ).to eq(true)
    end

    it "returns procedures in JSON payload when showProcedures param is true" do
      attachment = Attachment.create!(
        record: persisted_record,
        document: uploaded_file
      )

      get(path, params: query_params.merge(showAttachments: true), headers: headers)

      expect(response).to have_http_status(:ok)
      expect(response_record["attachments"].size).to eq(1)
      returned_attachment = response_record["attachments"].first
      expect(returned_attachment.keys).to match_array(
        ([:id] + ATTACHMENT_ATTRIBUTES).map { |k| k.to_s.camelize(:lower) }
      )
      expect(
        attachment_response_matches?(returned_attachment, attachment)
      ).to eq(true)
    end

    it "returns 404 if the record is deleted" do
      persisted_record = cases(:fernando_deleted_right_knee)
      path = "/patients/#{persisted_record.id}"

      get(path, params: query_params, headers: headers)

      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 if the patient is deleted" do
      persisted_record = cases(:deleted_patient_active_left_hip)
      path = "/patients/#{persisted_record.id}"

      get(path, params: query_params, headers: headers)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST create" do
    let(:path) { endpoint_root_path }
    let(:valid_params) do
      a_case = cases(:fernando_left_hip)
      case_attributes = a_case.attributes.dup.symbolize_keys
      case_attributes[:patient] = a_case.patient.attributes.dup.symbolize_keys
      case_attributes.delete(:patient_id)
      a_case.patient.destroy
      a_case.destroy
      { case: case_attributes }
    end

    it_behaves_like "an endpoint that supports JSON, form, and text exchange", :post

    context "when patient is posted as nested attribute" do
      it "creates a new active persisted record for the case and returns JSON" do
        a_case = cases(:fernando_left_hip)
        case_attributes = a_case.attributes.dup.symbolize_keys
        case_attributes[:patient] = a_case.patient.attributes.dup.symbolize_keys
        case_attributes.delete(:patient_id)
        a_case.patient.destroy
        a_case.destroy
        payload = query_params.merge(case: case_attributes)

        expect {
          post(path, params: payload.to_json, headers: headers)
        }.to change(Case, :count).by(1)

        expect(response).to have_http_status(:created)

        persisted_record = Case.last
        expect(persisted_record.active?).to eq(true)
        CASE_ATTRIBUTES.each do |attr|
          expect(case_attributes[attr].to_s).to eq(persisted_record.send(attr).to_s)
        end
        expect(case_response_matches?(response_record, persisted_record)).to eq(true)
      end

      it "creates a new active persisted record for the patient" do
        a_case = cases(:fernando_left_hip)
        case_attributes = a_case.attributes.dup.symbolize_keys
        patient_attributes = a_case.patient.attributes.dup.symbolize_keys
        case_attributes[:patient] = patient_attributes
        case_attributes.delete(:patient_id)
        a_case.patient.destroy
        a_case.destroy
        payload = query_params.merge(case: case_attributes)

        expect {
          post(path, params: payload.to_json, headers: headers)
        }.to change(Patient, :count).by(1)

        persisted_record = Patient.last
        expect(persisted_record.active?).to eq(true)

        expect(patient_response_matches?(json["case"]["patient"], persisted_record)).to eq(true)
        PATIENT_ATTRIBUTES.each do |attr|
          expect(patient_attributes[attr].to_s).to eq(persisted_record.send(attr).to_s)
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
        payload = query_params.merge(case: case_attributes)

        expect {
          post(path, params: payload.to_json, headers: headers)
        }.to_not change(Case, :count)

        expect(response).to have_http_status(:bad_request)
        expect(json["error"]["message"]).to match(/name/i)
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
        payload = query_params.merge(case: case_attributes)

        expect {
          post(path, params: payload.to_json, headers: headers)
        }.to change(Case, :count).by(1)

        expect(response).to have_http_status(:created)
        persisted_case_record = Case.last
        persisted_patient_record = Patient.last
        expect(persisted_case_record.active?).to eq(true)
        expect(persisted_patient_record.active?).to eq(true)
      end
    end

    context "when patient_id is posted" do
      it "creates a new persisted case associated to the patient" do
        patient = patients(:silvia)
        case_attributes = cases(:fernando_left_hip).attributes.dup.symbolize_keys
        case_attributes[:patient_id] = patient.id
        payload = query_params.merge(case: case_attributes)

        expect {
          post(path, params: payload.to_json, headers: headers)
        }.to change(Case, :count).by(1)

        persisted_record = Case.last

        CASE_ATTRIBUTES.each do |attr|
          expect(case_attributes[attr].to_s).to eq(persisted_record.send(attr).to_s)
        end
        expect(case_response_matches?(json["case"], persisted_record)).to eq(true)
        expect(patient_response_matches?(json["case"]["patient"], patient)).to eq(true)
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
          payload = query_params.merge(case: case_attributes)

          expect {
            post(path, params: payload.to_json, headers: headers)
          }.to change(Case, :count).by(1)

          patient.reload
          persisted_record = Case.last

          CASE_ATTRIBUTES.each do |attr|
            expect(case_attributes[attr].to_s).to eq(persisted_record.send(attr).to_s)
          end
          expect(case_response_matches?(json["case"], persisted_record)).to eq(true)
          expect(patient.name).to eq(original_patient_name)
          expect(patient.active?).to eq(true)
        end

        it "does not create a new patient" do
          patient = patients(:silvia)
          case_attributes = cases(:fernando_left_hip).attributes.dup.symbolize_keys
          case_attributes[:patient_id] = patient.id
          case_attributes[:patient] = { name: "New Patient Info" }
          payload = query_params.merge(case: case_attributes)

          expect {
            post(path, params: payload.to_json, headers: headers)
          }.to_not change(Patient, :count)
        end
      end

      it "returns 404 if patient is not found for patient_id" do
        expect(Patient.find_by_id(100)).to be_nil
        case_attributes = cases(:fernando_left_hip).attributes.dup.symbolize_keys
        case_attributes[:patient_id] = 100
        case_attributes[:patient] = { name: "Patient Info" }
        payload = query_params.merge(case: case_attributes)

        post(path, params: payload.to_json, headers: headers)

        expect(response).to have_http_status(:not_found)
      end
    end

    context "on unexpected input" do
      it "returns 400 on absent patient or patient id" do
        case_attributes = cases(:fernando_left_hip).attributes.dup.symbolize_keys
        case_attributes.delete(:patient_id)
        payload = query_params.merge(case: case_attributes)

        post(path, params: payload.to_json, headers: headers)

        expect(response).to have_http_status(:bad_request)
        expect(json["error"]["message"]).to match(/patient/i)
      end
    end
  end

  describe "PATCH update" do
    let(:persisted_record) { cases(:fernando_left_hip) }
    let(:path) { "#{endpoint_root_path}/#{persisted_record.id}" }
    let(:valid_params) do
      { case: { anatomy: "hip" } }
    end

    it_behaves_like "an endpoint that supports JSON, form, and text exchange", :patch

    it "updates an existing case record" do
      payload = { case: { anatomy: "knee", side: "right" } }

      patch(path, params: payload.to_json, headers: headers)

      persisted_record.reload
      expect(persisted_record.anatomy).to eq("knee")
      expect(persisted_record.side).to eq("right")
    end

    it "does not update patient information" do
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
      payload = query_params.merge(case: new_attributes)

      patch(path, params: payload.to_json, headers: headers)

      persisted_record.reload
      expect(persisted_record.patient.reload).to eq(patient)
      expect(persisted_record.patient.name).to eq(original_patient_name)
    end

    it "ignores status in request input" do
      persisted_record = cases(:fernando_deleted_right_knee)
      path = "#{endpoint_root_path}/#{persisted_record.id}"
      payload = query_params.merge(case: { status: "active" })

      patch(path, params: payload.to_json, headers: headers)

      persisted_record.reload
      expect(persisted_record.active?).to eq(false)
    end

    it "returns 404 and does not update when attempting to update a deleted record" do
      persisted_record = cases(:fernando_deleted_right_knee)
      path = "#{endpoint_root_path}/#{persisted_record.id}"
      new_attributes = { anatomy: "hip" }
      payload = query_params.merge(case: new_attributes)

      patch(path, params: payload.to_json, headers: headers)

      expect(response).to have_http_status(:not_found)
      persisted_record.reload
      expect(persisted_record.anatomy).to eq("hip")
    end
  end

  describe "DELETE" do
    let(:persisted_record) { cases(:fernando_left_hip) }
    let(:path) { "#{endpoint_root_path}/#{persisted_record.id}" }

    it_behaves_like "an endpoint that supports JSON, form, and text exchange", :delete

    it "soft-deletes an existing persisted record" do
      delete(path, headers: headers)

      expect(response).to have_http_status(:ok)
      expect(json["message"]).to eq("Deleted")

      expect(persisted_record.reload.active?).to eq(false)
    end

    it "returns 404 if persisted record does not exist" do
      expect(Case.find_by_id(100)).to be_nil

      delete("#{endpoint_root_path}/100", headers: headers)

      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 if record is already deleted" do
      persisted_record = cases(:fernando_deleted_right_knee)
      path = "#{endpoint_root_path}/#{persisted_record.id}"

      delete(path, headers: headers)

      expect(response).to have_http_status(:not_found)
    end
  end
end
