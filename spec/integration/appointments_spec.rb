require "spec_helper"

def validate_response_matches(response, record)
  appointment_response_matches?(response, record).should == true
  if record.patient
    patient_response_matches?(response["patient"], record.patient).should == true
  end
end

describe "appointments", type: :api do
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

      response.code.should == "200"
      response_records = json["appointments"]
      response_records.size.should == 2
      response_ids_for(response_records).any?{ |id| id.nil? }.should == false

      response_record_1 = pluck_response_record(response_records, @persisted_1.id)
      response_record_2 = pluck_response_record(response_records, @persisted_2.id)

      validate_response_matches(response_record_1, @persisted_1)
      validate_response_matches(response_record_2, @persisted_2)
    end

    it "filters by location" do
      @persisted_2.update_attributes!(location: "room 1")

      get "/appointments", query_params.merge(location: "room 1"), headers

      response.code.should == "200"
      response_records = json["appointments"]
      response_records.size.should == 1
      response_records.first["id"].should == @persisted_2.id
    end

    it "filters by trip_id" do
      @persisted_1.update_attributes!(trip_id: "2")

      get "/appointments", query_params.merge(trip_id: "2"), headers

      response.code.should == "200"
      response_records = json["appointments"]
      response_records.size.should == 1
      response_records.first["id"].should == @persisted_1.id
    end

    it "filters by multiple criteria" do
      @persisted_1.update_attributes!(location: "room 1", trip_id: "1")
      @persisted_2.update_attributes!(location: "room 1", trip_id: "2")

      get "/appointments", query_params.merge(
        location: "room 1", trip_id: "2"
      ), headers

      response.code.should == "200"
      response_records = json["appointments"]
      response_records.size.should == 1
      response_records.first["id"].should == @persisted_2.id
    end

    it "does not include records belonging to deleted patients" do
      persisted = appointments(:for_deleted_patient)

      get "/appointments", query_params, headers

      response.code.should == "200"
      response_ids_for(json["appointments"]).should_not include(persisted.id)
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

      response.code.should == "200"
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
           appointment: attributes.to_json,
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
             query_params.merge(appointment: attributes).to_json,
             headers
      }.to change(Appointment, :count).by(1)

      response.code.should == "201"

      response_record = json["appointment"]
      persisted_record = Appointment.last

      persisted_record.patient_id.should == patient.id
      APPOINTMENT_ATTRIBUTES.each do |attr|
        attributes[attr].should == persisted_record.send(attr)
      end
      appointment_response_matches?(response_record, persisted_record).should == true
      patient_response_matches?(response_record["patient"], patient).should == true
    end

    it "returns 400 if a patient id is not supplied" do
      attributes = appointments(:fernando_gt15).attributes.dup.symbolize_keys
      attributes.delete(:patient_id)

      expect {
        post "/appointments",
             query_params.merge(appointment: attributes).to_json,
             headers
      }.to_not change(Appointment, :count)

      response.code.should == "400"
      json["error"]["message"].should match(/patient/i)
    end

    it "returns 404 if patient is not found matching id" do
      attributes = appointments(:fernando_gt15).attributes.dup.symbolize_keys
      attributes[:patient_id] = 1
      Patient.find_by_id(1).should be_nil

      expect {
        post "/appointments",
             query_params.merge(appointment: attributes).to_json,
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
             query_params.merge(appointment: attributes).to_json,
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
          appointment: new_attributes.to_json,
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
        persisted_record.send(k).should_not == v
      end

      put "/appointments/#{persisted_record.id}",
          query_params.merge(appointment: new_attributes).to_json,
          headers

      response_record = json["appointment"]
      persisted_record.reload

      response.code.should == "200"
      attribute_keys = new_attributes.keys

      validate_response_matches(response_record, persisted_record)
      validate_response_matches(response_record, Appointment.new(new_attributes))
    end

    it "returns 400 if attempting to transfer to a different patient" do
      persisted_record = appointments(:fernando_gt15)
      original_patient = persisted_record.patient
      different_patient = patients(:silvia)
      different_patient.id.should_not == original_patient.id
      persisted_record.start_ordinal.should_not == 5
      original_start_ordinal = persisted_record.start_ordinal
      new_attributes = {
        start_ordinal: 5,
        patient_id: different_patient.id
      }

      put "/appointments/#{persisted_record.id}",
          query_params.merge(appointment: new_attributes).to_json,
          headers

      response.code.should == "400"
      json["error"]["message"].should match(/patient/i)

      persisted_record.reload
      persisted_record.start_ordinal.should == original_start_ordinal
      persisted_record.patient_id.should == original_patient.id
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
          query_params.merge(appointment: new_attributes).to_json,
          headers

      persisted_record.reload
      persisted_record.patient.name.should == original_patient_name
    end

    it "returns 404 if patient is deleted" do
      persisted_record = appointments(:for_deleted_patient)
      new_attributes = {
        start_time: Time.now + 1.week,
        start_ordinal: 5
      }

      put "/appointments/#{persisted_record.id}",
          query_params.merge(appointment: new_attributes).to_json,
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

      response.code.should == "200"
      json["message"].should == "Deleted"

      persisted_record.class.find_by_id(persisted_record.id).should be_nil
    end

    it "returns 404 if persisted record does not exist" do
      delete "/appointments/100", query_params, headers

      expect_not_found_response
    end
  end#delete

end