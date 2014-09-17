require "spec_helper"

def validate_response_match(response, record)
  APPOINTMENT_ATTRIBUTES.each do |attr|
    if %i(start_time end_time).include?(attr)
      Time.parse(response[attr.to_s.camelize(:lower)]).iso8601.should == record.send(attr).iso8601
    else
      response[attr.to_s.camelize(:lower)].should == record.send(attr)
    end
  end
  if record.patient
    PATIENT_ATTRIBUTES.each do |attr|
      if attr == :birth
        response["patient"][attr.to_s.camelize(:lower)].should == record.patient.send(attr).to_s(:db)
      else
        response["patient"][attr.to_s.camelize(:lower)].should == record.patient.send(attr)
      end
    end
  end
end

describe "appointments", type: :api do

  let(:query_params) { {} }

  describe "GET index" do
    let(:headers) { token_auth_header }

    before(:each) do
      @persisted_1 = FactoryGirl.create(:appointment)
      @persisted_2 = FactoryGirl.create(:appointment)
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
      response_records.map{ |r| r["id"] }.any?{ |id| id.nil? }.should == false

      response_record_1 = response_records.detect{ |r| r["id"] == @persisted_1.id }
      response_record_2 = response_records.detect{ |r| r["id"] == @persisted_2.id }

      validate_response_match(response_record_1, @persisted_1)
      validate_response_match(response_record_2, @persisted_2)
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
      persisted_3 = FactoryGirl.create(
        :appointment,
        patient: FactoryGirl.create(:deleted_patient)
      )

      get "/appointments", query_params, headers

      response.code.should == "200"
      response_records = json["appointments"]

      response_records.map{ |r| r["id"] }.should_not include(persisted_3.id)
    end
  end

  describe "GET show" do
    let(:headers) { token_auth_header }

    before(:each) do
      @persisted_patient = FactoryGirl.create(:patient)
      @persisted_record = FactoryGirl.create(:appointment, patient: @persisted_patient)
    end

    it "returns 401 if authentication headers are not present" do
      get "/appointments/#{@persisted_record.id}"

      expect_failed_authentication
    end

    it "returns a single persisted record as JSON" do
      get "/appointments/#{@persisted_record.id}", query_params, headers

      response.code.should == "200"
      response_record = json["appointment"]

      validate_response_match(response_record, @persisted_record)
    end

    it "returns 404 if there is no persisted record" do
      get "/appointments/#{@persisted_record.id + 1}", query_params, headers

      expect_not_found_response
    end

    it "returns 404 if patient is deleted" do
      persisted_record = FactoryGirl.create(:appointment,
        patient: FactoryGirl.create(:deleted_patient)
      )

      get "/appointments/#{persisted_record.id}", query_params, headers

      expect_not_found_response
    end
  end#show

  describe "POST create" do
    let(:headers) { token_auth_header.merge(json_content_header) }

    it "returns 401 if authentication headers are not present" do
      patient = FactoryGirl.create(:patient)
      attributes = FactoryGirl.attributes_for(:appointment).merge!(
        patient_id: patient.id
      )

      post "/appointments",
           appointment: attributes.to_json,
           "Content-Type" => "application/json"

      expect_failed_authentication
    end

    it "returns 400 if JSON content-type not specified"

    it "persists a new patient-associated record and returns JSON" do
      patient = FactoryGirl.create(:patient)
      attributes = FactoryGirl.attributes_for(:appointment).merge!(
        patient_id: patient.id
      )

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
      PATIENT_ATTRIBUTES.each do |attr|
        response_record["patient"][attr.to_s].to_s.should == patient.send(attr).to_s
      end
    end

    it "returns 400 if a patient id is not supplied" do
      attributes = FactoryGirl.attributes_for(:appointment)
      attributes.should_not include(:patient_id)

      expect {
        post "/appointments",
             query_params.merge(appointment: attributes).to_json,
             headers
      }.to_not change(Appointment, :count)

      response.code.should == "400"
      json["error"]["message"].should match(/patient/i)
    end

    it "returns 404 if patient is not found matching id" do
      attributes = FactoryGirl.attributes_for(:appointment).merge!(patient_id: 1)
      Patient.find_by_id(1).should be_nil

      expect {
        post "/appointments",
             query_params.merge(appointment: attributes).to_json,
             headers
      }.to_not change(Appointment, :count)

      expect_not_found_response
    end

    it "returns 404 if patient is deleted" do
      patient = FactoryGirl.create(:deleted_patient)
      attributes = FactoryGirl.attributes_for(:appointment).merge!(patient_id: patient.id)

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
      persisted_record = FactoryGirl.create(:appointment)
      new_attributes = { start_time: Time.now.utc + 1.week }

      put "/appointments/#{persisted_record.id}",
          appointment: new_attributes.to_json,
          "Content-Type" => "application/json"

      expect_failed_authentication
    end

    it "returns 400 if JSON content-type not specified"

    it "updates an existing appointment record" do
      persisted_record = FactoryGirl.create(:appointment)
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

      validate_response_match(response_record, persisted_record)
      validate_response_match(response_record, Appointment.new(new_attributes))
    end

    it "does not allow transfer to another patient" do
      patient = FactoryGirl.create(:patient)
      different_patient = FactoryGirl.create(:patient)
      persisted_record = FactoryGirl.create(:appointment, patient: patient)
      new_attributes = {
        start_ordinal: 5,
        patient_id: different_patient.id
      }

      put "/appointments/#{persisted_record.id}",
          query_params.merge(appointment: new_attributes).to_json,
          headers

      persisted_record.reload
      persisted_record.patient_id.should == patient.id
    end

    it "does not update patient information" do
      patient = FactoryGirl.create(:patient)
      original_patient_name = patient.name
      persisted_record = FactoryGirl.create(:appointment, patient: patient)
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
      persisted_record.patient.reload.should == patient
      persisted_record.patient.name.should == original_patient_name
    end

    it "returns 404 if patient is deleted" do
      patient = FactoryGirl.create(:deleted_patient)
      persisted_record = FactoryGirl.create(:appointment, patient: patient)
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
      persisted_record = FactoryGirl.create(:appointment)

      delete "/appointments/#{persisted_record.id}"

      expect_failed_authentication
    end

    it "hard-deletes an existing persisted record" do
      persisted_record = FactoryGirl.create(:appointment)

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