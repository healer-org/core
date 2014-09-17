require "spec_helper"

# TODO messaging & logging behavior
# TODO undelete functionality for administrator clients
describe "patients", type: :api do

  def response_should_match_persisted(response, persisted)
    PATIENT_ATTRIBUTES.each do |attr|
      if attr == :birth
        response[attr.to_s.camelize(:lower)].should == persisted.send(attr).to_s(:db)
      else
        response[attr.to_s.camelize(:lower)].to_s.should == persisted.send(attr).to_s
      end
    end
  end

  let(:query_params) { {} }

  describe "GET index" do
    let(:headers) { token_auth_header }

    before(:each) do
      @persisted_1 = FactoryGirl.create(:patient)
      @persisted_2 = FactoryGirl.create(:patient)
    end

    it "returns 401 if authentication headers are not present" do
      get "/patients"

      expect_failed_authentication
    end

    it "returns all records as JSON" do
      get "/patients", query_params, headers

      response.code.should == "200"
      response_records = json["patients"]
      response_records.size.should == 2
      response_records.map{ |r| r["id"] }.any?{ |id| id.nil? }.should == false

      response_record_1 = response_records.detect{ |r| r["id"] == @persisted_1.id }
      response_record_2 = response_records.detect{ |r| r["id"] == @persisted_2.id }

      response_should_match_persisted(response_record_1, @persisted_1)
      response_should_match_persisted(response_record_2, @persisted_2)
    end

    it "does not return deleted records" do
      @persisted_2.delete!

      get "/patients", query_params, headers

      response.code.should == "200"
      response_records = json["patients"]
      response_records.size.should == 1

      response_record = response_records.first

      response_should_match_persisted(response_record, @persisted_1)
    end

    it "does not return results for deleted records, even if asked" do
      @persisted_2.delete!

      get "/patients", query_params.merge(status: "deleted"), headers

      response.code.should == "200"
      response_records = json["patients"]
      response_records.size.should == 1

      response_records.map{ |r| r["id"] }.should_not include(@persisted_2.id)
    end

    context "when showCases param is true" do
      it "returns cases as additional JSON" do
        case1 = FactoryGirl.create(:active_case, patient: @persisted_1)
        case2 = FactoryGirl.create(:active_case, patient: @persisted_2)

        get "/patients", query_params.merge(showCases: true), headers

        response.code.should == "200"
        response_records = json["patients"]
        response_records.size.should == 2

        response_record_1 = response_records.detect{ |p| p["id"] == @persisted_1.id }
        response_record_2 = response_records.detect{ |p| p["id"] == @persisted_2.id }

        case1_result = response_record_1["cases"].first
        case2_result = response_record_2["cases"].first

        CASE_ATTRIBUTES.each do |attr|
          case1_result[attr.to_s].to_s.should == case1.send(attr).to_s
          case2_result[attr.to_s].to_s.should == case2.send(attr).to_s
        end
      end
    end
  end#index

  describe "GET show" do
    let(:headers) { token_auth_header }

    before(:each) do
      @persisted = FactoryGirl.create(:patient)
    end

    it "returns 401 if authentication headers are not present" do
      get "/patients/#{@persisted.id}"

      expect_failed_authentication
    end

    it "returns a single persisted record as JSON" do
      get "/patients/#{@persisted.id}", query_params, headers

      response.code.should == "200"
      response_record = json["patient"]
      response_record["id"].should == @persisted.id
      response_record["name"].should == @persisted.name
      response_record["birth"].to_s.should == @persisted.birth.to_s
    end

    it "returns 404 if there is no persisted record" do
      get "/patients/#{@persisted.id + 1}", query_params, headers

      expect_not_found_response
    end

    it "does not return status attribute" do
      get "/patients/#{@persisted.id}", query_params, headers

      response.code.should == "200"
      response_record = json["patient"]
      response_record.keys.should_not include("status")
      response_record.keys.should_not include("active")
    end

    it "returns 404 if the record is deleted" do
      persisted_record = FactoryGirl.create(:deleted_patient)

      get "/patients/#{persisted_record.id}", query_params, headers

      expect_not_found_response
    end

    context "when showCases param is true" do
      it "returns all cases as JSON" do
        case1 = FactoryGirl.create(:active_case, patient: @persisted)
        case2 = FactoryGirl.create(:active_case, patient: @persisted)

        get "/patients/#{@persisted.id}", query_params.merge(
          showCases: true
        ), headers

        response.code.should == "200"
        response_record = json["patient"]

        response_should_match_persisted(response_record, @persisted)

        cases = response_record["cases"]
        cases.size.should == 2
        CASE_ATTRIBUTES.each do |attr|
          cases[0][attr.to_s].to_s.should == case1.send(attr).to_s
          cases[1][attr.to_s].to_s.should == case2.send(attr).to_s
        end
      end
    end
  end#show

  describe "POST create" do
    let(:headers) { token_auth_header.merge(json_content_header) }

    it "returns 401 if authentication headers are not present" do
      attributes = FactoryGirl.attributes_for(:patient)

      post "/patients",
           { patient: attributes }.to_json,
           json_content_header

      expect_failed_authentication
    end

    it "returns 400 if JSON content-type not specified"

    it "creates a new active persisted record and returns JSON" do
      attributes = FactoryGirl.attributes_for(:patient)

      expect {
        post "/patients",
             query_params.merge( patient: attributes ).to_json,
             headers
      }.to change(Patient, :count).by(1)

      response.code.should == "201"

      response_record = json["patient"]
      persisted_record = Patient.last
      persisted_record.active?.should == true

      response_should_match_persisted(response_record, persisted_record)
    end

    it "returns 400 if name is not supplied" do
      attributes = FactoryGirl.attributes_for(:patient)
      attributes.delete(:name)

      post "/patients",
           query_params.merge(patient: attributes).to_json,
           headers

      response.code.should == "400"
      json["error"]["message"].should match(/name/i)
    end

    it "ignores status in request input" do
      attributes = FactoryGirl.attributes_for(:deleted_patient)

      post "/patients",
           query_params.merge(patient: attributes).to_json,
           headers

      response.code.should == "201"
      persisted_record = Patient.last
      persisted_record.active?.should == true
    end
  end#create

  describe "PUT update" do
    let(:headers) { token_auth_header.merge(json_content_header) }

    it "returns 401 if authentication headers are not present" do
      persisted_record = FactoryGirl.create(:patient)
      attributes = { name: "Juan Marco" }

      put "/patients/#{persisted_record.id}",
          { patient: attributes }.to_json,
          json_content_header

      expect_failed_authentication
    end

    it "returns 400 if JSON content-type not specified"

    it "updates an existing persisted record" do
      persisted_record = FactoryGirl.create(:patient)
      attributes = {
        name: "Juan Marco",
        birth: Date.parse("1977-08-12"),
        gender: "M",
        death: Date.parse("2014-07-12")
      }

      put "/patients/#{persisted_record.id}",
          query_params.merge(patient: attributes).to_json,
          headers

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

      put "/patients/#{persisted_record.id}",
          query_params.merge(patient: attributes).to_json,
          headers

      response.code.should == "200"
      response_record = json["patient"]
      response_record["name"].should == "Juana"
      response_record["birth"].should == "1977-08-12"
    end

    it "returns 404 if record does not exist" do
      attributes = {
        name: "Juana",
        birth: Date.parse("1977-08-12")
      }
      put "/patients/1",
          query_params.merge(patient: attributes).to_json,
          headers

      expect_not_found_response
    end

    it "returns 404 if the record is deleted" do
      persisted_record = FactoryGirl.create(:deleted_patient)
      attributes = { name: "Changed attributes" }

      put "/patients/#{persisted_record.id}",
          query_params.merge(patient: attributes).to_json,
          headers

      expect_not_found_response
    end

    it "ignores status in request input" do
      persisted_record = FactoryGirl.create(:patient)
      attributes = {
        name: "Juan Marco",
        status: "should_not_change"
      }

      put "/patients/#{persisted_record.id}",
          query_params.merge(patient: attributes).to_json,
          headers

      persisted_record.reload
      persisted_record.name.should == "Juan Marco"
      persisted_record.status.should == "active"
    end
  end#update

  describe "DELETE" do
    let(:headers) { token_auth_header }

    it "returns 401 if authentication headers are not present" do
      persisted_record = FactoryGirl.create(:patient)

      delete "/patients/#{persisted_record.id}"

      expect_failed_authentication
    end

    it "soft-deletes an existing persisted record" do
      persisted_record = FactoryGirl.create(:patient)

      delete "/patients/#{persisted_record.id}", query_params, headers

      response.code.should == "200"
      json["message"].should == "Deleted"

      persisted_record.reload.active?.should == false
    end

    it "returns 404 if persisted record does not exist" do
      delete "/patients/100", query_params, headers

      expect_not_found_response
    end
  end#delete

  describe "GET search" do
    let(:headers) { token_auth_header }

    it "returns 401 if authentication headers are not present" do
      get "/patients/search", query_params.merge({})

      expect_failed_authentication
    end

    it "returns empty result set on no query terms" do
      search_query = {}
      get "/patients/search", query_params.merge(search_query), headers

      response.code.should == "200"
      response_records = json["patients"]
      response_records.size.should == 0
    end

    it "returns patients by full name" do
      persisted = FactoryGirl.create(:patient, name: "Ramon")

      search_query = {q: "Ramon"}
      get "/patients/search", query_params.merge(search_query), headers

      response.code.should == "200"
      response_records = json["patients"]
      response_records.size.should == 1

      response_should_match_persisted(response_records[0], persisted)
    end

    it "returns only patients that match the query" do
      persisted_1 = FactoryGirl.create(:patient, name: "DeBarge")
      persisted_2 = FactoryGirl.create(:patient, name: "Ramon")

      search_query = {q: "Ramon"}
      get "/patients/search", query_params.merge(search_query), headers

      response.code.should == "200"
      response_records = json["patients"]
      response_records.size.should == 1

      response_should_match_persisted(response_records[0], persisted_2)
    end

    it "performs case-insensitive lookup" do
      persisted_1 = FactoryGirl.create(:patient, name: "DeBarge")
      persisted_2 = FactoryGirl.create(:patient, name: "Ramon")

      search_query = {q: "raMon"}
      get "/patients/search", query_params.merge(search_query), headers

      response.code.should == "200"
      response_records = json["patients"]
      response_records.size.should == 1

      response_should_match_persisted(response_records[0], persisted_2)
    end

    it "performs unicode-insensitive lookup" do
      skip("This feature may require some DB trickery or Sphinx conversion")
      persisted_1 = FactoryGirl.create(:patient, name: "DeBarge")
      persisted_2 = FactoryGirl.create(:patient, name: "Ramón")

      search_query = {q: "Ramon"}
      get "/patients/search", query_params.merge(search_query), headers

      response.code.should == "200"
      response_records = json["patients"]
      response_records.size.should == 1

      response_should_match_persisted(response_records[0], persisted_2)
    end

    it "searches by name containing spaces" do
      persisted_1 = FactoryGirl.create(:patient, name: "DeBarge")
      persisted_2 = FactoryGirl.create(:patient, name: "Ramon Johnson")

      search_query = {q: "ramon johnson"}
      get "/patients/search", query_params.merge(search_query), headers

      response.code.should == "200"
      response_records = json["patients"]
      response_records.size.should == 1

      response_should_match_persisted(response_records[0], persisted_2)
    end

    it "searches by partial name" do
      persisted_1 = FactoryGirl.create(:patient, name: "DeBarge")
      persisted_2 = FactoryGirl.create(:patient, name: "Ramon Johnson")

      search_query = {q: "ramon"}
      get "/patients/search", query_params.merge(search_query), headers

      response.code.should == "200"
      response_records = json["patients"]
      response_records.size.should == 1

      response_should_match_persisted(response_records[0], persisted_2)
    end

    it "searches by partial name" do
      persisted_1 = FactoryGirl.create(:patient, name: "DeBarge")
      persisted_2 = FactoryGirl.create(:patient, name: "Ramon Johnson")

      search_query = {q: "johnson"}
      get "/patients/search", query_params.merge(search_query), headers

      response.code.should == "200"
      response_records = json["patients"]
      response_records.size.should == 1

      response_should_match_persisted(response_records[0], persisted_2)
    end

    it "searches by fragments of name" do
      skip("Snakes in the burning pet shop")
      persisted = FactoryGirl.create(:patient, name: "Ramon The Rock Johnson")

      search_query = {q: "ramon johnson"}
      get "/patients/search", query_params.merge(search_query), headers

      response.code.should == "200"
      response_records = json["patients"]
      response_records.size.should == 1

      response_should_match_persisted(response_records[0], persisted)
    end
  end#search

end