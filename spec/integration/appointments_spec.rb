require "spec_helper"

describe "appointments", type: :api do

  let(:valid_request_attributes) { { "client_id" => "healer_spec" } }

  describe "GET index" do
    before(:each) do
      @persisted_1 = FactoryGirl.create(:appointment)
      @persisted_2 = FactoryGirl.create(:appointment)
    end

    it "returns all appointments as JSON, along with patient data" do
      get "/appointments", {}, valid_request_attributes

      response.code.should == "200"
      response_body = JSON.parse(response.body)
      response_records = response_body["appointments"]
      response_records.size.should == 2
      response_records.map{ |r| r["id"] }.any?{ |id| id.nil? }.should == false

      response_record_1 = response_records.detect{ |r| r["id"] == @persisted_1.id }
      response_record_2 = response_records.detect{ |r| r["id"] == @persisted_2.id }

      APPOINTMENT_ATTRIBUTES.each do |attr|
        response_record_1[attr].to_s.should == @persisted_1.send(attr).to_s
        response_record_2[attr].to_s.should == @persisted_2.send(attr).to_s
      end
      PATIENT_ATTRIBUTES.each do |attr|
        response_record_1["patient"][attr].to_s.should == @persisted_1.patient.send(attr).to_s
        response_record_2["patient"][attr].to_s.should == @persisted_2.patient.send(attr).to_s
      end
    end

    it "filters by location" do
      @persisted_2.update_attributes!(:location => "room 1")

      get "/appointments", { :location => "room 1" }, valid_request_attributes

      response.code.should == "200"
      response_body = JSON.parse(response.body)
      response_records = response_body["appointments"]
      response_records.size.should == 1
      response_records.first["id"].should == @persisted_2.id
    end

    it "filters by trip_id" do
      @persisted_1.update_attributes!(:trip_id => "2")

      get "/appointments", { :trip_id => "2" }, valid_request_attributes

      response.code.should == "200"
      response_body = JSON.parse(response.body)
      response_records = response_body["appointments"]
      response_records.size.should == 1
      response_records.first["id"].should == @persisted_1.id
    end

    it "filters by multiple criteria" do
      @persisted_1.update_attributes!(:location => "room 1", :trip_id => "1")
      @persisted_2.update_attributes!(:location => "room 1", :trip_id => "2")

      get "/appointments", { :location => "room 1", :trip_id => "2" }, valid_request_attributes

      response.code.should == "200"
      response_body = JSON.parse(response.body)
      response_records = response_body["appointments"]
      response_records.size.should == 1
      response_records.first["id"].should == @persisted_2.id
    end
  end

  describe "POST create" do
    it "persists a new patient-associated record and returns JSON" do
      patient = FactoryGirl.create(:patient)
      attributes = FactoryGirl.attributes_for(:appointment).merge!(:patient_id => patient.id)

      expect {
        post "/appointments", { appointment: attributes }
      }.to change(Appointment, :count).by(1)

      response.code.should == "201"

      response_record = JSON.parse(response.body)["appointment"]
      persisted_record = Appointment.last
      persisted_record.patient_id.should == patient.id
      APPOINTMENT_ATTRIBUTES.each do |attr|
        attributes[attr.to_sym].to_s.should == persisted_record.send(attr).to_s
      end
      PATIENT_ATTRIBUTES.each do |attr|
        response_record["patient"][attr].to_s.should == patient.send(attr).to_s
      end
    end

    it "returns 400 if a patient id is not supplied" do
      attributes = FactoryGirl.attributes_for(:appointment)
      attributes.should_not include(:patient_id)

      expect {
        post "/appointments", { appointment: attributes }
      }.to_not change(Appointment, :count)

      response.code.should == "400"
      response_body = JSON.parse(response.body)
      response_body["error"]["message"].should match(/patient/i)
    end

    it "returns 404 if patient is not found matching id" do
      attributes = FactoryGirl.attributes_for(:appointment).merge!(:patient_id => 1)
      Patient.find_by_id(1).should be_nil

      expect {
        post "/appointments", { appointment: attributes }
      }.to_not change(Appointment, :count)

      response.code.should == "404"
      response_body = JSON.parse(response.body)
      response_body["error"]["message"].should == "Not Found"
    end

    # TODO: decide whether to allow appointment creation to update patient info.
    #       is there a case where that's useful?
  end

  describe "DELETE" do
    it "hard-deletes an existing persisted record" do
      persisted_record = FactoryGirl.create(:appointment)

      delete "/appointments/#{persisted_record.id}"

      response.code.should == "200"
      response_body = JSON.parse(response.body)
      response_body["message"].should == "Deleted"

      persisted_record.class.find_by_id(persisted_record.id).should be_nil
    end

    it "returns 404 if persisted record does not exist" do
      delete "/appointments/100"

      response.code.should == "404"
      response_body = JSON.parse(response.body)
      response_body["error"]["message"].should == "Not Found"
    end
  end#delete

end