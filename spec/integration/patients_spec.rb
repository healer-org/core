require "spec_helper"

# TODO client id validation, e.g.:
# it_behaves_like "an endpoint that requires a valid client ID"
# it_behaves_like "an endpoint that requires a <special type of> client ID"

# TODO messaging & logging behavior
# TODO undelete functionality for administrator clients
describe "patients", type: :api do

  let(:valid_request_attributes) { { "client_id" => "healer_spec" } }

  describe "GET index" do
    before(:each) do
      @persisted_1 = FactoryGirl.create(:patient)
      @persisted_2 = FactoryGirl.create(:patient)
    end

    it "returns all records as JSON" do
      get "/patients", {}, valid_request_attributes

      response.code.should == "200"
      response_body = JSON.parse(response.body)
      response_records = response_body["patients"]
      response_records.size.should == 2
      response_records.map{ |r| r["id"] }.any?{ |id| id.nil? }.should == false

      response_record_1 = response_records.detect{ |r| r["id"] == @persisted_1.id }
      response_record_2 = response_records.detect{ |r| r["id"] == @persisted_2.id }

      PATIENT_ATTRIBUTES.each do |attr|
        response_record_1[attr].to_s.should == @persisted_1.send(attr).to_s
        response_record_2[attr].to_s.should == @persisted_2.send(attr).to_s
      end
    end

    it "does not return deleted records" do
      @persisted_2.delete!

      get "/patients", {}, valid_request_attributes

      response.code.should == "200"
      response_body = JSON.parse(response.body)
      response_records = response_body["patients"]
      response_records.size.should == 1

      response_record = response_records.first

      PATIENT_ATTRIBUTES.each do |attr|
        response_record[attr].to_s.should == @persisted_1.send(attr).to_s
      end
    end

    it "does not return results for deleted records, even if asked" do
      @persisted_2.delete!

      get "/patients?status=deleted", {}, valid_request_attributes

      response.code.should == "200"
      response_body = JSON.parse(response.body)
      response_records = response_body["patients"]
      response_records.size.should == 1

      response_records.map{ |r| r["id"] }.should_not include(@persisted_2.id)
    end

    context "when showCases param is true" do
      it "returns cases as additional JSON" do
        case1 = FactoryGirl.create(:case, patient: @persisted_1)
        case2 = FactoryGirl.create(:case, patient: @persisted_2)

        get "/patients?showCases=true", {}, valid_request_attributes

        response.code.should == "200"
        response_body = JSON.parse(response.body)
        response_records = response_body["patients"]
        response_records.size.should == 2

        response_record_1 = response_records.detect{ |p| p["id"] == @persisted_1.id }
        response_record_2 = response_records.detect{ |p| p["id"] == @persisted_2.id }

        case1_result = response_record_1["cases"].first
        case2_result = response_record_2["cases"].first

        CASE_ATTRIBUTES.each do |attr|
          case1_result[attr].to_s.should == case1.send(attr).to_s
          case2_result[attr].to_s.should == case2.send(attr).to_s
        end
      end
    end
  end#index

  describe "GET show" do
    before(:each) do
      @persisted = FactoryGirl.create(:patient)
    end

    it "returns a single persisted record as JSON" do
      get "/patients/#{@persisted.id}", {}, valid_request_attributes

      response.code.should == "200"
      response_record = JSON.parse(response.body)["patient"]
      response_record["id"].should == @persisted.id
      response_record["name"].should == @persisted.name
      response_record["birth"].to_s.should == @persisted.birth.to_s
    end

    it "returns 404 if there is no persisted record" do
      get "/patients/#{@persisted.id + 1}"

      response.code.should == "404"
      response_body = JSON.parse(response.body)
      response_body["error"]["message"].should == "Not Found"
    end

    it "does not return status attribute" do
      get "/patients/#{@persisted.id}", {}, valid_request_attributes

      response.code.should == "200"
      response_record = JSON.parse(response.body)["patient"]
      response_record.keys.should_not include("status")
      response_record.keys.should_not include("active")
    end

    it "returns 404 if the record is deleted" do
      persisted_record = FactoryGirl.create(:deleted_patient)

      get "/patients/#{persisted_record.id}"

      response.code.should == "404"
      response_body = JSON.parse(response.body)
      response_body["error"]["message"].should == "Not Found"
    end

    context "when showCases param is true" do
      it "returns all cases as JSON" do
        case1 = FactoryGirl.create(:case, patient: @persisted)
        case2 = FactoryGirl.create(:case, patient: @persisted)

        get "/patients/#{@persisted.id}?showCases=true", {}, valid_request_attributes

        response.code.should == "200"
        response_record = JSON.parse(response.body)["patient"]

        PATIENT_ATTRIBUTES.each do |attr|
          response_record[attr].to_s.should == @persisted.send(attr).to_s
        end

        cases = response_record["cases"]
        cases.size.should == 2
        CASE_ATTRIBUTES.each do |attr|
          cases[0][attr].to_s.should == case1.send(attr).to_s
          cases[1][attr].to_s.should == case2.send(attr).to_s
        end
      end
    end
  end#show

  describe "POST create" do
    it "creates a new active persisted record and returns JSON" do
      attributes = FactoryGirl.attributes_for(:patient)

      expect {
        post "/patients", { patient: attributes }
      }.to change(Patient, :count).by(1)

      response.code.should == "201"

      response_record = JSON.parse(response.body)["patient"]
      persisted_record = Patient.last
      persisted_record.active?.should == true
      PATIENT_ATTRIBUTES.each do |attr|
        response_record[attr].to_s.should == persisted_record.send(attr).to_s
      end
    end

    it "returns 400 if name is not supplied" do
      attributes = FactoryGirl.attributes_for(:patient)
      attributes.delete(:name)

      post "/patients", { patient: attributes }

      response.code.should == "400"
      response_body = JSON.parse(response.body)
      response_body["error"]["message"].should match(/name/i)
    end

    it "ignores status in request input" do
      attributes = FactoryGirl.attributes_for(:deleted_patient)

      post "/patients", { patient: attributes }

      response.code.should == "201"
      persisted_record = Patient.last
      persisted_record.active?.should == true
    end
  end#create

  describe "PUT update" do
    it "updates an existing persisted record" do
      persisted_record = FactoryGirl.create(:patient)
      attributes = {
        name: "Juan Marco",
        birth: Date.parse("1977-08-12"),
        gender: "M",
        death: Date.parse("2014-07-12")
      }

      put "/patients/#{persisted_record.id}", { patient: attributes }

      persisted_record.reload
      persisted_record.name.should == "Juan Marco"
      persisted_record.gender.should == "M"
      persisted_record.birth.to_s.should == Date.parse("1977-08-12").to_s
      persisted_record.death.to_s.should == Date.parse("2014-07-12").to_s
    end

    it "returns the updated record as JSON" do
      persisted_record = FactoryGirl.create(:patient)
      attributes = {
        name: "Juana",
        birth: Date.parse("1977-08-12")
      }

      put "/patients/#{persisted_record.id}", { patient: attributes }

      response.code.should == "200"
      response_record = JSON.parse(response.body)["patient"]
      response_record["name"].should == "Juana"
      response_record["birth"].should == "1977-08-12"
    end

    it "returns 404 if record does not exist" do
      attributes = {
        name: "Juana",
        birth: Date.parse("1977-08-12")
      }
      put "/patients/1", { patient: attributes }

      response.code.should == "404"
      response_body = JSON.parse(response.body)
      response_body["error"]["message"].should == "Not Found"
    end

    it "returns 404 if the record is deleted" do
      persisted_record = FactoryGirl.create(:deleted_patient)

      put "/patients/#{persisted_record.id}", {
        patient: { name: "Changed attributes" }
      }

      response.code.should == "404"
      response_body = JSON.parse(response.body)
      response_body["error"]["message"].should == "Not Found"
    end

    it "ignores status in request input" do
      persisted_record = FactoryGirl.create(:patient)
      attributes = {
        name: "Juan Marco",
        status: "should_not_change"
      }

      put "/patients/#{persisted_record.id}", { patient: attributes }

      persisted_record.reload
      persisted_record.name.should == "Juan Marco"
      persisted_record.status.should == "active"
    end
  end#update

  describe "DELETE" do
    it "soft-deletes an existing persisted record" do
      persisted_record = FactoryGirl.create(:patient)

      delete "/patients/#{persisted_record.id}"

      response.code.should == "200"
      response_body = JSON.parse(response.body)
      response_body["message"].should == "Deleted"

      persisted_record.reload.active?.should == false
    end

    it "returns 404 if persisted record does not exist" do
      delete "/patients/100"

      response.code.should == "404"
      response_body = JSON.parse(response.body)
      response_body["error"]["message"].should == "Not Found"
    end
  end#delete

end