# frozen_string_literal: true

def validate_response_matches(response, record)
  expect(appointment_response_matches?(response, record)).to eq(true)
  return unless record.patient

  expect(
    patient_response_matches?(response["patient"], record.patient)
  ).to eq(true)
end

RSpec.describe "appointments", type: :request do
  fixtures :appointments, :patients

  let(:query_params) { {} }
  let(:endpoint_root_path) { "/appointments" }
  let(:headers) { default_headers }

  def response_records
    json["appointments"]
  end

  describe "GET index" do
    let(:path) { endpoint_root_path }

    before(:each) do
      @persisted_1 = appointments(:fernando_gt15)
      @persisted_2 = appointments(:silvia_gt15)
    end

    it_behaves_like "an endpoint that supports JSON, form, and text exchange", :get

    it "returns all appointments as JSON, along with patient data" do
      get(path, params: query_params, headers: headers)

      expect(response).to have_http_status(:ok)
      expect(response_records.size).to eq(2)
      expect(response_ids_for(response_records).any?(&:nil?)).to eq(false)

      response_record_1 = pluck_response_record(response_records, @persisted_1.id)
      response_record_2 = pluck_response_record(response_records, @persisted_2.id)

      validate_response_matches(response_record_1, @persisted_1)
      validate_response_matches(response_record_2, @persisted_2)
    end

    it "filters by location" do
      @persisted_2.update!(location: "room 1")

      get(path, params: query_params.merge(location: "room 1"), headers: headers)

      expect(response).to have_http_status(:ok)
      expect(response_records.size).to eq(1)
      expect(response_records.first["id"]).to eq(@persisted_2.id)
    end

    it "filters by trip_id" do
      @persisted_1.update!(trip_id: "2")

      get(path, params: query_params.merge(trip_id: "2"), headers: headers)

      expect(response).to have_http_status(:ok)
      expect(response_records.size).to eq(1)
      expect(response_records.first["id"]).to eq(@persisted_1.id)
    end

    it "filters by multiple criteria" do
      @persisted_1.update!(location: "room 1", trip_id: "1")
      @persisted_2.update!(location: "room 1", trip_id: "2")

      get(
        path,
        params: query_params.merge(location: "room 1", trip_id: "2"),
        headers: headers
      )

      expect(response).to have_http_status(:ok)
      expect(response_records.size).to eq(1)
      expect(response_records.first["id"]).to eq(@persisted_2.id)
    end

    it "does not include records belonging to deleted patients" do
      persisted = appointments(:for_deleted_patient)

      get(path, params: query_params, headers: headers)

      expect(response).to have_http_status(:ok)
      expect(response_ids_for(json["appointments"])).not_to include(persisted.id)
    end
  end

  describe "GET show" do
    let(:persisted_record) { appointments(:fernando_gt15) }
    let(:path) { "#{endpoint_root_path}/#{persisted_record.id}" }

    it_behaves_like "an endpoint that supports JSON, form, and text exchange", :get

    it "returns a single persisted record as JSON" do
      get(path, params: query_params, headers: headers)

      expect(response).to have_http_status(:ok)
      response_record = json["appointment"]

      validate_response_matches(response_record, persisted_record)
    end

    it "returns 404 if there is no persisted record" do
      path = "#{endpoint_root_path}/#{persisted_record.id + 1}"

      get(path, params: query_params, headers: headers)

      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 if patient is deleted" do
      persisted_record = appointments(:for_deleted_patient)
      path = "#{endpoint_root_path}/#{persisted_record.id + 1}"

      get(path, params: query_params, headers: headers)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST create" do
    let(:path) { endpoint_root_path }
    let(:valid_params) do
      {
        appointment: appointments(:fernando_gt15).attributes.dup
      }
    end

    it_behaves_like "an endpoint that supports JSON, form, and text exchange", :post

    it "persists a new patient-associated record and returns JSON" do
      patient = patients(:fernando)
      appointment = appointments(:fernando_gt15)
      attributes = appointment.attributes.dup.symbolize_keys
      appointment.destroy
      payload = query_params.merge(appointment: attributes)

      expect {
        post(path, params: payload.to_json, headers: headers)
      }.to change(Appointment, :count).by(1)

      expect(response).to have_http_status(:created)

      response_record = json["appointment"]
      persisted_record = Appointment.last

      expect(persisted_record.patient_id).to eq(patient.id)
      APPOINTMENT_ATTRIBUTES.each do |attr|
        expect(attributes[attr]).to eq(persisted_record.send(attr))
      end
      expect(appointment_response_matches?(response_record, persisted_record)).to eq(true)
      expect(patient_response_matches?(response_record["patient"], patient)).to eq(true)
    end

    it "returns 400 if a patient id is not supplied" do
      attributes = appointments(:fernando_gt15).attributes.dup.symbolize_keys
      attributes.delete(:patient_id)
      payload = query_params.merge(appointment: attributes)

      expect {
        post(path, params: payload.to_json, headers: headers)
      }.to_not change(Appointment, :count)

      expect(response).to have_http_status(:bad_request)
      expect(json["error"]["message"]).to match(/patient/i)
    end

    it "returns 404 if patient is not found matching id" do
      attributes = appointments(:fernando_gt15).attributes.dup.symbolize_keys
      attributes[:patient_id] = 1
      expect(Patient.find_by_id(1)).to be_nil
      payload = query_params.merge(appointment: attributes)

      expect {
        post(path, params: payload.to_json, headers: headers)
      }.to_not change(Appointment, :count)

      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 if patient is deleted" do
      patient = patients(:deleted)
      attributes = appointments(:fernando_gt15).attributes.dup.symbolize_keys
      attributes[:patient_id] = patient.id
      payload = query_params.merge(appointment: attributes)

      expect {
        post(path, params: payload.to_json, headers: headers)
      }.to_not change(Appointment, :count)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH update" do
    let(:persisted_record) { appointments(:fernando_gt15) }
    let(:path) { "#{endpoint_root_path}/#{persisted_record.id}" }
    let(:valid_params) do
      {
        appointment: appointments(:fernando_gt15).attributes.dup
      }
    end

    it_behaves_like "an endpoint that supports JSON, form, and text exchange", :patch

    it "updates an existing appointment record" do
      new_attributes = {
        start: Time.now.utc + 1.week,
        order: 5,
        location: "room 1",
        end: Time.now.utc + 2.weeks
      }
      payload = query_params.merge(appointment: new_attributes)

      new_attributes.each do |k, v|
        expect(persisted_record.send(k)).not_to eq(v)
      end

      patch(path, params: payload.to_json, headers: headers)

      response_record = json["appointment"]
      persisted_record.reload

      expect(response).to have_http_status(:ok)

      validate_response_matches(response_record, persisted_record)
      validate_response_matches(response_record, Appointment.new(new_attributes))
    end

    it "returns 400 if attempting to transfer to a different patient" do
      original_patient = persisted_record.patient
      different_patient = patients(:silvia)
      expect(different_patient.id).not_to eq(original_patient.id)
      expect(persisted_record.order).not_to eq(5)
      original_order = persisted_record.order
      new_attributes = {
        order: 5,
        patient_id: different_patient.id
      }
      payload = query_params.merge(appointment: new_attributes)

      patch(path, params: payload.to_json, headers: headers)

      expect(response).to have_http_status(:bad_request)
      expect(json["error"]["message"]).to match(/patient/i)

      persisted_record.reload
      expect(persisted_record.order).to eq(original_order)
      expect(persisted_record.patient_id).to eq(original_patient.id)
    end

    it "does not update patient information" do
      original_patient_name = persisted_record.patient.name
      new_attributes = {
        order: 500,
        patient: {
          name: "New Patient Name"
        }
      }
      payload = query_params.merge(appointment: new_attributes)

      patch(path, params: payload.to_json, headers: headers)

      persisted_record.reload
      expect(persisted_record.patient.name).to eq(original_patient_name)
    end

    it "returns 404 if patient is deleted" do
      persisted_record = appointments(:for_deleted_patient)
      path = "#{endpoint_root_path}/#{persisted_record.id + 1}"
      new_attributes = {
        start_time: Time.now + 1.week,
        order: 5
      }
      payload = query_params.merge(appointment: new_attributes)

      patch(path, params: payload.to_json, headers: headers)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE" do
    let(:persisted_record) { appointments(:fernando_gt15) }
    let(:path) { "#{endpoint_root_path}/#{persisted_record.id}" }

    it_behaves_like "an endpoint that supports JSON, form, and text exchange", :delete

    it "hard-deletes an existing persisted record" do
      delete(path, headers: headers)

      expect(response).to have_http_status(:ok)
      expect(json["message"]).to eq("Deleted")

      expect(persisted_record.class.find_by_id(persisted_record.id)).to be_nil
    end

    it "returns 404 if persisted record does not exist" do
      path = "#{endpoint_root_path}/#{persisted_record.id + 1}"

      delete(path, headers: headers)

      expect(response).to have_http_status(:not_found)
    end
  end
end
