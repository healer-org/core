require "rails_helper"

# TODO messaging & logging behavior
# TODO undelete functionality for administrator clients
RSpec.describe "patients", type: :api do
  fixtures :patients, :cases

  let(:query_params) { {} }

  describe "GET index" do
    let(:headers) { token_auth_header }

    before(:each) do
      @persisted_1 = patients(:fernando)
      @persisted_2 = patients(:silvia)
    end

    it "returns 401 if authentication headers are not present" do
      get "/patients"

      expect_failed_authentication
    end

    it "returns all records as JSON" do
      get "/patients", query_params, headers

      expect_success_response
      response_records = json["patients"]

      expect(response_ids_for(response_records).any?{ |id| id.nil? }).to eq(false)

      response_record_1 = pluck_response_record(response_records, @persisted_1.id)
      response_record_2 = pluck_response_record(response_records, @persisted_2.id)

      expect(patient_response_matches?(response_record_1, @persisted_1)).to eq(true)
      expect(patient_response_matches?(response_record_2, @persisted_2)).to eq(true)
    end

    it "does not return deleted records" do
      deleted_patient = patients(:deleted)

      get "/patients", query_params, headers

      expect_success_response
      response_records = json["patients"]

      expect(response_records.map{ |r| r[:id] }).not_to include(deleted_patient.id)
    end

    it "does not return results for deleted records, even if asked" do
      @persisted_2.delete!

      get "/patients", query_params.merge(status: "deleted"), headers

      expect_success_response
      expect(response_ids_for(json["patients"])).not_to include(@persisted_2.id)
    end

    context "when showCases param is true" do
      it "returns cases as additional JSON" do
        case1 = cases(:fernando_left_hip)
        case2 = cases(:silvia_right_foot)

        get "/patients", query_params.merge(showCases: true), headers

        expect_success_response
        response_records = json["patients"]

        response_record_1 = pluck_response_record(response_records, @persisted_1.id)
        response_record_2 = pluck_response_record(response_records, @persisted_2.id)

        expect(response_record_1["cases"].size).to eq(1)
        expect(response_record_2["cases"].size).to eq(2)

        case1_result = response_record_1["cases"].first
        case2_result = response_record_2["cases"].detect{ |c| c["side"] == "right" }

        expect(case_response_matches?(case1_result, case1)).to eq(true)
        expect(case_response_matches?(case2_result, case2)).to eq(true)
      end
    end
  end#index

  describe "GET show" do
    let(:headers) { token_auth_header }

    before(:each) do
      @persisted = patients(:fernando)
    end

    it "returns 401 if authentication headers are not present" do
      get "/patients/#{@persisted.id}"

      expect_failed_authentication
    end

    it "returns a single persisted record as JSON" do
      get "/patients/#{@persisted.id}", query_params, headers

      expect_success_response
      response_record = json["patient"]
      expect(response_record["id"]).to eq(@persisted.id)
      expect(response_record["name"]).to eq(@persisted.name)
      expect(response_record["birth"].to_s).to eq(@persisted.birth.to_s)
    end

    it "returns 404 if there is no persisted record" do
      get "/patients/#{@persisted.id + 1}", query_params, headers

      expect_not_found_response
    end

    it "does not return status attribute" do
      get "/patients/#{@persisted.id}", query_params, headers

      expect_success_response
      response_record = json["patient"]
      expect(response_record.keys).not_to include("status")
      expect(response_record.keys).not_to include("active")
    end

    it "returns 404 if the record is deleted" do
      persisted_record = patients(:deleted)

      get "/patients/#{persisted_record.id}", query_params, headers

      expect_not_found_response
    end

    context "when showCases param is true" do
      it "returns all cases as JSON" do
        persisted = patients(:silvia)
        case1 = cases(:silvia_left_foot)
        case2 = cases(:silvia_right_foot)

        get "/patients/#{persisted.id}", query_params.merge(
          showCases: true
        ), headers

        expect_success_response
        response_record = json["patient"]

        expect(patient_response_matches?(response_record, persisted)).to eq(true)

        cases = response_record["cases"]
        expect(cases.size).to eq(2)
        expect(case_response_matches?(cases[0], case1)).to eq(true)
        expect(case_response_matches?(cases[1], case2)).to eq(true)
      end
    end
  end#show

  describe "POST create" do
    let(:headers) { token_auth_header.merge(json_content_header) }

    it "returns 401 if authentication headers are not present" do
      post "/patients",
           { patient: patients(:fernando).attributes },
           json_content_header

      expect_failed_authentication
    end

    it "returns 400 if JSON content-type not specified"

    it "creates a new active persisted record and returns JSON" do
      expect {
        post "/patients",
             query_params.merge( patient: patients(:fernando).attributes ),
             headers
      }.to change(Patient, :count).by(1)

      expect_created_response

      response_record = json["patient"]
      persisted_record = Patient.last
      expect(persisted_record.active?).to eq(true)

      expect(patient_response_matches?(response_record, persisted_record)).to eq(true)
    end

    it "returns 400 if name is not supplied" do
      attributes = patients(:fernando).attributes
      attributes.delete("name")

      post "/patients",
           query_params.merge(patient: attributes),
           headers

      expect_bad_request
      expect(json["error"]["message"]).to match(/name/i)
    end

    it "ignores status in request input" do
      post "/patients",
           query_params.merge(patient: patients(:deleted).attributes),
           headers

      expect_created_response
      persisted_record = Patient.last
      expect(persisted_record.active?).to eq(true)
    end
  end#create

  describe "PUT update" do
    let(:headers) { token_auth_header.merge(json_content_header) }

    it "returns 401 if authentication headers are not present" do
      persisted_record = patients(:fernando)
      attributes = { name: "Juan Marco" }

      put "/patients/#{persisted_record.id}",
          { patient: attributes },
          json_content_header

      expect_failed_authentication
    end

    it "returns 400 if JSON content-type not specified"

    it "updates an existing persisted record" do
      persisted_record = patients(:fernando)
      attributes = {
        name: "Juan Marco",
        birth: Date.parse("1977-08-12"),
        gender: "M",
        death: Date.parse("2014-07-12")
      }

      put "/patients/#{persisted_record.id}",
          query_params.merge(patient: attributes),
          headers

      persisted_record.reload
      expect(persisted_record.name).to eq("Juan Marco")
      expect(persisted_record.gender).to eq("M")
      expect(persisted_record.birth.to_s).to eq(Date.parse("1977-08-12").to_s)
      expect(persisted_record.death.to_s).to eq(Date.parse("2014-07-12").to_s)
    end

    it "returns the updated record as JSON" do
      persisted_record = patients(:silvia)
      attributes = {
        name: "Juana",
        birth: Date.parse("1977-08-12")
      }

      put "/patients/#{persisted_record.id}",
          query_params.merge(patient: attributes),
          headers

      expect_success_response
      response_record = json["patient"]
      expect(response_record["name"]).to eq("Juana")
      expect(response_record["birth"]).to eq("1977-08-12")
    end

    it "returns 404 if record does not exist" do
      attributes = {
        name: "Juana",
        birth: Date.parse("1977-08-12")
      }
      put "/patients/1",
          query_params.merge(patient: attributes),
          headers

      expect_not_found_response
    end

    it "returns 404 if the record is deleted" do
      persisted_record = patients(:deleted)
      attributes = { name: "Changed attributes" }

      put "/patients/#{persisted_record.id}",
          query_params.merge(patient: attributes),
          headers

      expect_not_found_response
    end

    it "ignores status in request input" do
      persisted_record = patients(:fernando)
      attributes = {
        name: "Juan Marco",
        status: "should_not_change"
      }

      put "/patients/#{persisted_record.id}",
          query_params.merge(patient: attributes),
          headers

      persisted_record.reload
      expect(persisted_record.name).to eq("Juan Marco")
      expect(persisted_record.status).to eq("active")
    end
  end#update

  describe "DELETE" do
    let(:headers) { token_auth_header }

    it "returns 401 if authentication headers are not present" do
      persisted_record = patients(:fernando)

      delete "/patients/#{persisted_record.id}"

      expect_failed_authentication
    end

    it "soft-deletes an existing persisted record" do
      persisted_record = patients(:fernando)

      delete "/patients/#{persisted_record.id}", query_params, headers

      expect_success_response
      expect(json["message"]).to eq("Deleted")

      expect(persisted_record.reload.active?).to eq(false)
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

      expect_success_response
      response_records = json["patients"]
      expect(response_records.size).to eq(0)
    end

    it "returns patients by full name" do
      persisted_record = patients(:fernando)
      persisted_record.update_attributes!(name: "Ramon")

      search_query = {q: "Ramon"}
      get "/patients/search", query_params.merge(search_query), headers

      expect_success_response
      response_records = json["patients"]
      expect(response_records.size).to eq(1)

      expect(patient_response_matches?(response_records[0], persisted_record)).to eq(true)
    end

    it "returns only patients that match the query" do
      persisted_1 = patients(:fernando)
      persisted_2 = patients(:silvia)
      persisted_1.update_attributes!(name: "DeBarge")
      persisted_2.update_attributes!(name: "Ramon")

      search_query = {q: "Ramon"}
      get "/patients/search", query_params.merge(search_query), headers

      expect_success_response
      response_records = json["patients"]
      expect(response_records.size).to eq(1)

      expect(patient_response_matches?(response_records[0], persisted_2)).to eq(true)
    end

    it "performs case-insensitive lookup" do
      persisted = patients(:silvia)
      persisted.update_attributes!(name: "Ramon")

      search_query = {q: "raMon"}
      get "/patients/search", query_params.merge(search_query), headers

      expect_success_response
      response_records = json["patients"]
      expect(response_records.size).to eq(1)

      expect(patient_response_matches?(response_records[0], persisted)).to eq(true)
    end

    it "performs unicode-insensitive lookup" do
      skip("This feature may require some DB trickery or Sphinx conversion")
      persisted = patients(:fernando)
      persisted.update_attributes!(name: "Ramón")

      search_query = {q: "Ramon"}
      get "/patients/search", query_params.merge(search_query), headers

      expect_success_response
      response_records = json["patients"]
      expect(response_records.size).to eq(1)

      expect(patient_response_matches?(response_records[0], persisted)).to eq(true)
    end

    it "searches by name containing spaces" do
      persisted = patients(:fernando)
      persisted.update_attributes!(name: "Ramon Johnson")

      search_query = {q: "ramon johnson"}
      get "/patients/search", query_params.merge(search_query), headers

      expect_success_response
      response_records = json["patients"]
      expect(response_records.size).to eq(1)

      expect(patient_response_matches?(response_records[0], persisted)).to eq(true)
    end

    it "searches by partial name" do
      persisted = patients(:fernando)
      persisted.update_attributes!(name: "Ramon Johnson")

      search_query = {q: "ramon"}
      get "/patients/search", query_params.merge(search_query), headers

      expect_success_response
      response_records = json["patients"]
      expect(response_records.size).to eq(1)

      expect(patient_response_matches?(response_records[0], persisted)).to eq(true)
    end

    it "searches by partial name" do
      persisted = patients(:fernando)
      persisted.update_attributes!(name: "Ramon Johnson")

      search_query = {q: "johnson"}
      get "/patients/search", query_params.merge(search_query), headers

      expect_success_response
      response_records = json["patients"]
      expect(response_records.size).to eq(1)

      expect(patient_response_matches?(response_records[0], persisted)).to eq(true)
    end

    it "searches by fragments of name" do
      skip("Snakes in the burning pet shop")
      persisted = patients(:fernando)
      persisted.update_attributes!(name: "Ramon The Rock Johnson")

      search_query = {q: "ramon johnson"}
      get "/patients/search", query_params.merge(search_query), headers

      expect_success_response
      response_records = json["patients"]
      expect(response_records.size).to eq(1)

      expect(patient_response_matches?(response_records[0], persisted)).to eq(true)
    end
  end#search

end