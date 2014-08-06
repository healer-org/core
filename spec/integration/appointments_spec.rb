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

end