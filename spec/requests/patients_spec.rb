# frozen_string_literal: true

# TODO: messaging & logging behavior
# TODO: undelete functionality for administrator clients

RSpec.describe "patients", type: :request do
  fixtures :patients, :cases

  let(:query_params) { {} }
  let(:endpoint_root_path) { "/patients" }
  let(:headers) { default_headers }

  def response_records
    json["patients"]
  end

  def response_record
    json["patient"]
  end

  describe "GET index" do
    let(:path) { endpoint_root_path }
    let(:persisted_record_1) { patients(:fernando) }
    let(:persisted_record_2) { patients(:silvia) }

    it_behaves_like "a standard JSON-compliant endpoint", :get

    it "returns all records as JSON" do
      get(path, params: query_params, headers: headers)

      expect(response).to have_http_status(:ok)
      expect(response_ids_for(response_records).any?(&:nil?)).to eq(false)

      response_record_1 = pluck_response_record(response_records, persisted_record_1.id)
      response_record_2 = pluck_response_record(response_records, persisted_record_2.id)

      expect(patient_response_matches?(response_record_1, persisted_record_1)).to eq(true)
      expect(patient_response_matches?(response_record_2, persisted_record_2)).to eq(true)
    end

    it "does not return deleted records" do
      deleted_patient = patients(:deleted)

      get(path, params: query_params, headers: headers)

      expect(response).to have_http_status(:ok)
      expect(response_records.map { |r| r[:id] }).not_to include(deleted_patient.id)
    end

    it "does not return results for deleted records, even if asked" do
      persisted_record_2.delete!

      get(path, params: query_params.merge(status: "deleted"), headers: headers)

      expect(response).to have_http_status(:ok)
      expect(response_ids_for(json["patients"])).not_to include(persisted_record_2.id)
    end

    context "when showCases param is true" do
      it "returns cases as additional JSON" do
        case1 = cases(:fernando_left_hip)
        case2 = cases(:silvia_right_foot)

        get(path, params: query_params.merge(showCases: true), headers: headers)

        expect(response).to have_http_status(:ok)

        response_record_1 = pluck_response_record(response_records, persisted_record_1.id)
        response_record_2 = pluck_response_record(response_records, persisted_record_2.id)

        expect(response_record_1["cases"].size).to eq(1)
        expect(response_record_2["cases"].size).to eq(2)

        case1_result = response_record_1["cases"].first
        case2_result = response_record_2["cases"].detect { |c| c["side"] == "right" }

        expect(case_response_matches?(case1_result, case1)).to eq(true)
        expect(case_response_matches?(case2_result, case2)).to eq(true)
      end
    end
  end

  describe "GET show" do
    let(:persisted_record) { patients(:fernando) }
    let(:path) { "#{endpoint_root_path}/#{persisted_record.id}" }

    it_behaves_like "a standard JSON-compliant endpoint", :get

    it "returns a single persisted record as JSON" do
      get(path, params: query_params, headers: headers)

      expect(response).to have_http_status(:ok)
      expect(response_record["id"]).to eq(persisted_record.id)
      expect(response_record["name"]).to eq(persisted_record.name)
      expect(response_record["birth"].to_s).to eq(persisted_record.birth.to_s)
    end

    it "returns 404 if there is no persisted record" do
      path = "#{endpoint_root_path}/#{persisted_record.id + 1}"

      get(path, params: query_params, headers: headers)

      expect(response).to have_http_status(:not_found)
    end

    it "does not return status attribute" do
      get(path, params: query_params, headers: headers)

      expect(response).to have_http_status(:ok)
      expect(response_record.keys).not_to include("status")
      expect(response_record.keys).not_to include("active")
    end

    it "returns 404 if the record is deleted" do
      persisted_record = patients(:deleted)
      path = "#{endpoint_root_path}/#{persisted_record.id}"

      get(path, params: query_params, headers: headers)

      expect(response).to have_http_status(:not_found)
    end

    context "when showCases param is true" do
      let(:persisted_record) { patients(:silvia) }

      it "returns all cases as JSON" do
        case1 = cases(:silvia_left_foot)
        case2 = cases(:silvia_right_foot)

        get(path, params: query_params.merge(showCases: true), headers: headers)

        expect(response).to have_http_status(:ok)

        expect(
          patient_response_matches?(response_record, persisted_record)
        ).to eq(true)

        cases = response_record["cases"]
        expect(cases.size).to eq(2)
        response_case1 = cases.detect { |c| c["id"] == case1.id }
        response_case2 = cases.detect { |c| c["id"] == case2.id }
        expect(case_response_matches?(response_case1, case1)).to eq(true)
        expect(case_response_matches?(response_case2, case2)).to eq(true)
      end
    end
  end

  describe "POST create" do
    let(:path) { endpoint_root_path }
    let(:valid_params) { { patient: patients(:fernando).attributes } }

    it_behaves_like "a standard JSON-compliant endpoint", :post

    it "creates a new active persisted record and returns JSON" do
      payload = query_params.merge(patient: patients(:fernando).attributes)

      expect {
        post(path, params: payload.to_json, headers: headers)
      }.to change(Patient, :count).by(1)

      expect(response).to have_http_status(:created)

      persisted_record = Patient.last
      expect(persisted_record.active?).to eq(true)

      expect(patient_response_matches?(response_record, persisted_record)).to eq(true)
    end

    it "returns 400 if name is not supplied" do
      attributes = patients(:fernando).attributes
      attributes.delete("name")
      payload = query_params.merge(patient: attributes)

      post(path, params: payload.to_json, headers: headers)

      expect(response).to have_http_status(:bad_request)
      expect(json["error"]["message"]).to match(/name/i)
    end

    it "ignores status in request input" do
      payload = query_params.merge(patient: patients(:deleted).attributes)

      post(path, params: payload.to_json, headers: headers)

      expect(response).to have_http_status(:created)
      persisted_record = Patient.last
      expect(persisted_record.active?).to eq(true)
    end
  end

  describe "PATCH update" do
    let(:persisted_record) { patients(:fernando) }
    let(:path) { "#{endpoint_root_path}/#{persisted_record.id}" }
    let(:valid_params) { { patient: { name: "Jon Marko" } } }

    it_behaves_like "a standard JSON-compliant endpoint", :patch

    it "updates an existing persisted record" do
      attributes = {
        name: "Juan Marco",
        birth: Date.parse("1977-08-12"),
        gender: "M",
        death: Date.parse("2014-07-12")
      }
      payload = query_params.merge(patient: attributes)

      patch(path, params: payload.to_json, headers: headers)

      persisted_record.reload
      expect(persisted_record.name).to eq("Juan Marco")
      expect(persisted_record.gender).to eq("M")
      expect(persisted_record.birth.to_s).to eq(Date.parse("1977-08-12").to_s)
      expect(persisted_record.death.to_s).to eq(Date.parse("2014-07-12").to_s)
    end

    it "returns the updated record as JSON" do
      persisted_record = patients(:silvia)
      path = "#{endpoint_root_path}/#{persisted_record.id}"

      attributes = {
        name: "Juana",
        birth: Date.parse("1977-08-12")
      }
      payload = query_params.merge(patient: attributes)

      patch(path, params: payload.to_json, headers: headers)

      expect(response).to have_http_status(:ok)
      expect(response_record["name"]).to eq("Juana")
      expect(response_record["birth"]).to eq("1977-08-12")
    end

    it "returns 404 if record does not exist" do
      path = "#{endpoint_root_path}/#{persisted_record.id + 1}"
      attributes = {
        name: "Juana",
        birth: Date.parse("1977-08-12")
      }
      payload = query_params.merge(patient: attributes)

      patch(path, params: payload.to_json, headers: headers)

      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 if the record is deleted" do
      persisted_record = patients(:deleted)
      path = "#{endpoint_root_path}/#{persisted_record.id}"

      payload = query_params.merge(patient: { name: "Changed attributes" })

      patch(path, params: payload.to_json, headers: headers)

      expect(response).to have_http_status(:not_found)
    end

    it "ignores status in request input" do
      attributes = {
        name: "Juan Marco",
        status: "should_not_change"
      }
      payload = query_params.merge(patient: attributes)

      patch(path, params: payload.to_json, headers: headers)

      persisted_record.reload
      expect(persisted_record.name).to eq("Juan Marco")
      expect(persisted_record.status).to eq("active")
    end
  end

  describe "DELETE" do
    let(:persisted_record) { patients(:fernando) }
    let(:path) { "#{endpoint_root_path}/#{persisted_record.id}" }

    it_behaves_like "a standard JSON-compliant endpoint", :delete

    it "soft-deletes an existing persisted record" do
      delete(path, headers: headers)

      expect(response).to have_http_status(:ok)
      expect(json["message"]).to eq("Deleted")

      expect(persisted_record.reload.active?).to eq(false)
    end

    it "returns 404 if persisted record does not exist" do
      path = "#{endpoint_root_path}/#{persisted_record.id + 1}"

      delete(path, headers: headers)

      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 if persisted record is already deleted" do
      persisted_record = patients(:deleted)
      path = "#{endpoint_root_path}/#{persisted_record.id}"

      delete(path, headers: headers)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET search" do
    let(:persisted_record) { patients(:fernando) }
    let(:path) { "#{endpoint_root_path}/search" }

    it "returns empty result set on no query terms" do
      search_query = {}
      get(path, params: query_params.merge(search_query), headers: headers)

      expect(response).to have_http_status(:ok)
      expect(response_records.size).to eq(0)
    end

    it "returns patients by full name" do
      persisted_record.update_attributes!(name: "Ramon")

      search_query = { q: "Ramon" }
      get(path, params: query_params.merge(search_query), headers: headers)

      expect(response).to have_http_status(:ok)
      expect(response_records.size).to eq(1)

      expect(
        patient_response_matches?(response_records[0], persisted_record)
      ).to eq(true)
    end

    it "returns only patients that match the query" do
      other_persisted_record = patients(:silvia)
      persisted_record.update_attributes!(name: "DeBarge")
      other_persisted_record.update_attributes!(name: "Ramon")

      search_query = { q: "Ramon" }
      get(path, params: query_params.merge(search_query), headers: headers)

      expect(response).to have_http_status(:ok)
      expect(response_records.size).to eq(1)
      expect(
        patient_response_matches?(response_records[0], other_persisted_record)
      ).to eq(true)
    end

    it "performs case-insensitive lookup" do
      persisted_record.update_attributes!(name: "Ramon")

      search_query = { q: "raMon" }
      get(path, params: query_params.merge(search_query), headers: headers)

      expect(response).to have_http_status(:ok)
      expect(response_records.size).to eq(1)

      expect(
        patient_response_matches?(response_records[0], persisted_record)
      ).to eq(true)
    end

    it "performs unicode-insensitive lookup" do
      skip("This feature may require some DB trickery or Sphinx conversion")
      persisted_record.update_attributes!(name: "Ramón")

      search_query = { q: "Ramon" }
      get(path, params: query_params.merge(search_query), headers: headers)

      expect(response).to have_http_status(:ok)
      expect(response_records.size).to eq(1)

      expect(
        patient_response_matches?(response_records[0], persisted_record)
      ).to eq(true)
    end

    it "searches by name containing spaces" do
      persisted_record.update_attributes!(name: "Ramon Johnson")

      search_query = { q: "ramon johnson" }
      get(path, params: query_params.merge(search_query), headers: headers)

      expect(response).to have_http_status(:ok)
      expect(response_records.size).to eq(1)

      expect(
        patient_response_matches?(response_records[0], persisted_record)
      ).to eq(true)
    end

    it "searches by partial name" do
      persisted_record.update_attributes!(name: "Ramon Johnson")

      search_query = { q: "ramon" }
      get(path, params: query_params.merge(search_query), headers: headers)

      expect(response).to have_http_status(:ok)
      expect(response_records.size).to eq(1)

      expect(
        patient_response_matches?(response_records[0], persisted_record)
      ).to eq(true)
    end

    it "searches by partial name" do
      persisted_record.update_attributes!(name: "Ramon Johnson")

      search_query = { q: "johnson" }
      get(path, params: query_params.merge(search_query), headers: headers)

      expect(response).to have_http_status(:ok)
      expect(response_records.size).to eq(1)

      expect(
        patient_response_matches?(response_records[0], persisted_record)
      ).to eq(true)
    end

    it "searches by fragments of name" do
      skip("Snakes in the burning pet shop")
      persisted_record.update_attributes!(name: "Ramon The Rock Johnson")

      search_query = { q: "ramon johnson" }
      get(path, params: query_params.merge(search_query), headers: headers)

      expect(response).to have_http_status(:ok)
      expect(response_records.size).to eq(1)

      expect(
        patient_response_matches?(response_records[0], persisted_record)
      ).to eq(true)
    end
  end
end
