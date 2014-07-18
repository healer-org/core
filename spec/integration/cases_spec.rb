require "spec_helper"

# TODO client id validation

describe "cases", type: :api do

  let(:valid_attributes) { { "client_id" => "healer_spec" } }

  describe "GET index" do
    it "returns all cases as JSON" do
      patient1 = Patient.create!(
        name: "Juan",
        birth: Date.parse("1975-05-28"),
        gender: "M",
      )
      patient2 = Patient.create!(
        name: "Juana",
        birth: Date.parse("1977-08-12"),
        gender: "F",
        death: Date.parse("2014-07-04")
      )
      case1 = Case.create!(patient_id: patient1.id)
      case2 = Case.create!(patient_id: patient2.id)

      get "/cases", {}, valid_attributes

      response.code.should == "200"
      results = JSON.parse(response.body)
      cases = results["cases"]
      cases.size.should == 2
      cases.map{ |c| c["id"] }.any?{ |id| id.nil? }.should == false

      p_case1 = cases.detect{ |c| c["id"] == case1.id }
      p_case2 = cases.detect{ |c| c["id"] == case2.id }

      p_case1["patient"]["name"].should == "Juan"
      p_case1["patient"]["birth"].should == "1975-05-28"
      p_case1["patient"]["gender"].should == "M"

      p_case2["patient"]["name"].should == "Juana"
      p_case2["patient"]["birth"].should == "1977-08-12"
      p_case2["patient"]["gender"].should == "F"
    end
  end#index

  describe "GET show" do
    it "returns a single case as JSON" do
      patient = Patient.create!(
        name: "Juan",
        birth: Date.parse("1975-05-28"),
        gender: "M",
      )
      case_record = Case.create!(
        patient_id: patient.id,
        anatomy: "knee",
        side: "left"
      )

      get "/cases/#{case_record.id}", {}, valid_attributes

      response.code.should == "200"
      result = JSON.parse(response.body)["case"]
      result["id"].should == case_record.id
      result["anatomy"].should == "knee"
      result["side"].should == "left"
      result["patient"]["name"].should == "Juan"
      result["patient"]["birth"].should == "1975-05-28"
      result["patient"]["gender"].should == "M"
    end

    it "returns 404 if there is no record for the case" do
      get "/cases/100"

      response.code.should == "404"
      result = JSON.parse(response.body)
      result["error"]["message"].should == "Not Found"
    end
  end#show

  describe "POST create" do
    context "when patient is posted as nested attribute" do
      it "creates a new patient" do
        attributes = {
          anatomy: "knee",
          patient: {
            name: "Juan",
            birth: Date.parse("1975-05-28"),
            gender: "M"
          }
        }

        expect {
          post "/cases", { case: attributes }
        }.to change(Patient, :count).by(1)

        new_patient = Patient.last
        new_patient.name.should == "Juan"
        new_patient.birth.to_s.should == Date.parse("1975-05-28").to_s
        new_patient.gender.should == "M"
      end

      it "creates a new case" do
        attributes = {
          anatomy: "knee",
          side: "right",
          patient: { name: "Juan" }
        }

        expect {
          post "/cases", { case: attributes }
        }.to change(Case, :count).by(1)

        new_case = Case.last
        new_case.anatomy.should == "knee"
        new_case.side.should == "right"
      end

      it "returns 400 if patient name is not supplied" do
        attributes = {
          anatomy: "knee",
          side: "right",
          patient: { gender: "M" }
        }

        expect {
          post "/cases", { case: attributes }
        }.to_not change(Case, :count)

        response.code.should == "400"
        result = JSON.parse(response.body)
        result["error"]["message"].should match(/name/i)
      end
    end

    context "when patient_id is posted" do
      before(:each) do
        @patient = Patient.create!(name: "Perry Winkle")
      end

      it "creates a new case" do
        attributes = {
          anatomy: "knee",
          side: "right",
          patient: { name: "Juan" }
        }

        expect {
          post "/cases", { case: attributes }
        }.to change(Case, :count).by(1)

        new_case = Case.last
        new_case.anatomy.should == "knee"
        new_case.side.should == "right"
      end

      context "and patient nested attributes are posted" do
        it "does not update the persisted patient with the posted attributes" do
          attributes = {
            anatomy: "hip",
            side: "left",
            patient_id: @patient.id,
            patient: { name: "Juan" }
          }

          expect {
            post "/cases", { case: attributes }
          }.to change(Case, :count).by(1)

          @patient.reload.name.should == "Perry Winkle"
          new_case = Case.last
          new_case.anatomy.should == "hip"
          new_case.side.should == "left"
          new_case.patient.should == @patient
        end

        it "does not create a new patient" do
          attributes = {
            anatomy: "hip",
            side: "left",
            patient_id: @patient.id,
            patient: { name: "Juan" }
          }

          expect {
            post "/cases", { case: attributes }
          }.to_not change(Patient, :count)
        end
      end

      it "returns 404 if patient is not found for patient_id" do
        attributes = {
          anatomy: "hip",
          side: "left",
          patient_id: 100,
          patient: { name: "Juan" }
        }

        post "/cases", { case: attributes }

        response.code.should == "404"
        result = JSON.parse(response.body)
        result["error"]["message"].should == "Not Found"
      end
    end

    context "on unexpected input" do
      it "returns 400 on absent patient or patient id" do
        attributes = {
          anatomy: "hip",
          side: "left"
        }

        post "/cases", { case: attributes }

        response.code.should == "400"
        result = JSON.parse(response.body)
        result["error"]["message"].should match(/patient/i)
      end
    end
  end#create

  describe "PUT update" do
    it "updates an existing case record" do
      patient = Patient.create!(
        name: "Juan",
        birth: Date.parse("1975-05-28"),
        gender: "M",
      )
      case_record = Case.create!(
        patient_id: patient.id,
        anatomy: "knee",
        side: "left"
      )

      attributes = {
        anatomy: "hip",
        side: "right"
      }

      put "/cases/#{case_record.id}", { case: attributes }

      case_record.reload
      case_record.anatomy.should == "hip"
      case_record.side.should == "right"
    end

    it "does not update patient information" do
      patient = Patient.create!(
        name: "Juan",
        birth: Date.parse("1975-05-28"),
        gender: "M",
      )
      other_patient = Patient.create!(
        name: "Juana",
        birth: Date.parse("1977-05-28"),
        gender: "F",
      )
      case_record = Case.create!(
        patient_id: patient.id,
        anatomy: "knee",
        side: "left"
      )

      attributes = {
        anatomy: "hip",
        side: "right",
        patient_id: patient.id,
        patient: {
          name: "Juanita"
        }
      }

      put "/cases/#{case_record.id}", { case: attributes }

      case_record.reload
      case_record.patient.should == patient
    end
  end#update

end