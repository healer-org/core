require "rails_helper"

def validate_response_matches(response, record)
  expect(appointment_response_matches?(response, record)).to eq(true)
  if record.patient
    expect(patient_response_matches?(response["patient"], record.patient)).to eq(true)
  end
end

RSpec.describe "appointments", type: :api do
  fixtures :appointments, :patients

  let(:query_params) { {} }

  describe "GET index" do
    let(:headers) { token_auth_header }

    before(:each) do
      @persisted_1 = appointments(:fernando_gt15)
      @persisted_2 = appointments(:silvia_gt15)
    end

    it "returns 401 if authentication headers are not present" do
      get "/appointments"

      expect_failed_authentication
    end

    it "returns all appointments as JSON, along with patient data" do
      get "/appointments", query_params, headers

      expect_success_response
      response_records = json["appointments"]
      expect(response_records.size).to eq(2)
      expect(response_ids_for(response_records).any?{ |id| id.nil? }).to eq(false)

      response_record_1 = pluck_response_record(response_records, @persisted_1.id)
      response_record_2 = pluck_response_record(response_records, @persisted_2.id)

      validate_response_matches(response_record_1, @persisted_1)
      validate_response_matches(response_record_2, @persisted_2)
    end

    it "filters by location" do
      @persisted_2.update_attributes!(location: "room 1")

      get "/appointments", query_params.merge(location: "room 1"), headers

      expect_success_response
      response_records = json["appointments"]
      expect(response_records.size).to eq(1)
      expect(response_records.first["id"]).to eq(@persisted_2.id)
    end

    it "filters by trip_id" do
      @persisted_1.update_attributes!(trip_id: "2")

      get "/appointments", query_params.merge(trip_id: "2"), headers

      expect_success_response
      response_records = json["appointments"]
      expect(response_records.size).to eq(1)
      expect(response_records.first["id"]).to eq(@persisted_1.id)
    end

    it "filters by multiple criteria" do
      @persisted_1.update_attributes!(location: "room 1", trip_id: "1")
      @persisted_2.update_attributes!(location: "room 1", trip_id: "2")

      get "/appointments", query_params.merge(
        location: "room 1", trip_id: "2"
      ), headers

      expect_success_response
      response_records = json["appointments"]
      expect(response_records.size).to eq(1)
      expect(response_records.first["id"]).to eq(@persisted_2.id)
    end

    it "does not include records belonging to deleted patients" do
      persisted = appointments(:for_deleted_patient)

      get "/appointments", query_params, headers

      expect_success_response
      expect(response_ids_for(json["appointments"])).not_to include(persisted.id)
    end
  end

  describe "GET show" do
    let(:headers) { token_auth_header }

    before(:each) do
      @persisted_record = appointments(:fernando_gt15)
    end

    it "returns 401 if authentication headers are not present" do
      get "/appointments/#{@persisted_record.id}"

      expect_failed_authentication
    end

    it "returns a single persisted record as JSON" do
      get "/appointments/#{@persisted_record.id}", query_params, headers

      expect_success_response
      response_record = json["appointment"]

      validate_response_matches(response_record, @persisted_record)
    end

    it "returns 404 if there is no persisted record" do
      get "/appointments/#{@persisted_record.id + 1}", query_params, headers

      expect_not_found_response
    end

    it "returns 404 if patient is deleted" do
      persisted_record = appointments(:for_deleted_patient)

      get "/appointments/#{persisted_record.id}", query_params, headers

      expect_not_found_response
    end
  end#show

  describe "POST create" do
    let(:headers) { token_auth_header.merge(json_content_header) }

    it "returns 401 if authentication headers are not present" do
      attributes = appointments(:fernando_gt15).attributes.dup

      post "/appointments",
           appointment: attributes,
           "Content-Type" => "application/json"

      expect_failed_authentication
    end

    it "returns 400 if JSON content-type not specified"

    it "persists a new patient-associated record and returns JSON" do
      patient = patients(:fernando)
      appointment = appointments(:fernando_gt15)
      attributes = appointment.attributes.dup.symbolize_keys
      appointment.destroy

      expect {
        post "/appointments",
             query_params.merge(appointment: attributes),
             headers
      }.to change(Appointment, :count).by(1)

      expect_created_response

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

      expect {
        post "/appointments",
             query_params.merge(appointment: attributes),
             headers
      }.to_not change(Appointment, :count)

      expect_bad_request
      expect(json["error"]["message"]).to match(/patient/i)
    end

    it "returns 404 if patient is not found matching id" do
      attributes = appointments(:fernando_gt15).attributes.dup.symbolize_keys
      attributes[:patient_id] = 1
      expect(Patient.find_by_id(1)).to be_nil

      expect {
        post "/appointments",
             query_params.merge(appointment: attributes),
             headers
      }.to_not change(Appointment, :count)

      expect_not_found_response
    end

    it "returns 404 if patient is deleted" do
      patient = patients(:deleted)
      attributes = appointments(:fernando_gt15).attributes.dup.symbolize_keys
      attributes[:patient_id] = patient.id

      expect {
        post "/appointments",
             query_params.merge(appointment: attributes),
             headers
      }.to_not change(Appointment, :count)

      expect_not_found_response
    end
  end

  describe "PUT update" do
    let(:headers) { token_auth_header.merge(json_content_header) }

    it "returns 401 if authentication headers are not present" do
      persisted_record = appointments(:fernando_gt15)
      new_attributes = { start_time: Time.now.utc + 1.week }

      put "/appointments/#{persisted_record.id}",
          appointment: new_attributes,
          "Content-Type" => "application/json"

      expect_failed_authentication
    end

    it "returns 400 if JSON content-type not specified"

    it "updates an existing appointment record" do
      persisted_record = appointments(:fernando_gt15)
      new_attributes = {
        start_time: Time.now.utc + 1.week,
        start_ordinal: 5,
        location: "room 1",
        end_time: Time.now.utc + 2.weeks
      }

      new_attributes.each do |k,v|
        expect(persisted_record.send(k)).not_to eq(v)
      end

      put "/appointments/#{persisted_record.id}",
          query_params.merge(appointment: new_attributes),
          headers

      response_record = json["appointment"]
      persisted_record.reload

      expect_success_response

      validate_response_matches(response_record, persisted_record)
      validate_response_matches(response_record, Appointment.new(new_attributes))
    end

    it "returns 400 if attempting to transfer to a different patient" do
      persisted_record = appointments(:fernando_gt15)
      original_patient = persisted_record.patient
      different_patient = patients(:silvia)
      expect(different_patient.id).not_to eq(original_patient.id)
      expect(persisted_record.start_ordinal).not_to eq(5)
      original_start_ordinal = persisted_record.start_ordinal
      new_attributes = {
        start_ordinal: 5,
        patient_id: different_patient.id
      }

      put "/appointments/#{persisted_record.id}",
          query_params.merge(appointment: new_attributes),
          headers

      expect_bad_request
      expect(json["error"]["message"]).to match(/patient/i)

      persisted_record.reload
      expect(persisted_record.start_ordinal).to eq(original_start_ordinal)
      expect(persisted_record.patient_id).to eq(original_patient.id)
    end

    it "does not update patient information" do
      persisted_record = appointments(:fernando_gt15)
      original_patient_name = persisted_record.patient.name
      new_attributes = {
        start_ordinal: 500,
        patient: {
          name: "New Patient Name"
        }
      }

      put "/appointments/#{persisted_record.id}",
          query_params.merge(appointment: new_attributes),
          headers

      persisted_record.reload
      expect(persisted_record.patient.name).to eq(original_patient_name)
    end

    it "returns 404 if patient is deleted" do
      persisted_record = appointments(:for_deleted_patient)
      new_attributes = {
        start_time: Time.now + 1.week,
        start_ordinal: 5
      }

      put "/appointments/#{persisted_record.id}",
          query_params.merge(appointment: new_attributes),
          headers

      expect_not_found_response
    end
  end

  describe "DELETE" do
    let(:headers) { token_auth_header }

    it "returns 401 if authentication headers are not present" do
      persisted_record = appointments(:fernando_gt15)

      delete "/appointments/#{persisted_record.id}"

      expect_failed_authentication
    end

    it "hard-deletes an existing persisted record" do
      persisted_record = appointments(:fernando_gt15)

      delete "/appointments/#{persisted_record.id}", query_params, headers

      expect_success_response
      expect(json["message"]).to eq("Deleted")

      expect(persisted_record.class.find_by_id(persisted_record.id)).to be_nil
    end

    it "returns 404 if persisted record does not exist" do
      delete "/appointments/100", query_params, headers

      expect_not_found_response
    end
  end#delete

end