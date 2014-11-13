require "spec_helper"

describe Patient do
  fixtures :patients, :cases

  describe "#delete!" do
    before(:each) do
      @patient = patients(:silvia)
    end

    it "sets status value to 'deleted'" do
      @patient.delete!

      expect(@patient.reload.status).to eq("deleted")
    end

    it "deletes all attached cases" do
      case_1 = cases(:silvia_left_foot)
      case_2 = cases(:silvia_right_foot)

      expect(case_1.active?).to eq(true)
      expect(case_2.active?).to eq(true)

      @patient.delete!

      expect(case_1.reload.active?).to eq(false)
      expect(case_2.reload.active?).to eq(false)
    end

    it "does not swallow errors if case fails to be deleted" do
      case_1 = cases(:silvia_left_foot)

      allow_any_instance_of(Case).to receive(:delete!).and_raise "Fail"

      expect { @patient.delete! }.to raise_error
    end

    it "does not delete patient case fails to be deleted" do
      case_1 = cases(:silvia_left_foot)

      allow_any_instance_of(Case).to receive(:delete!).and_raise "Fail"

      expect { @patient.delete! }.to raise_error

      expect(@patient.reload.active?).to eq(true)
    end

    it "logs the deletion" do
      allow(Rails.logger).to receive(:info)
      expect(Rails.logger).to receive(:info).at_least(:once).with(
        "id=#{@patient.id} object=Patient action=delete"
      )

      @patient.delete!
    end

    it "sends an event message"
  end

  describe "#active?" do
    it "is false if status is deleted" do
      patient = patients(:deleted)

      expect(patient.active?).to eq(false)
    end

    %w(
      active
    ).each do |status|
      it "is true if status is #{status}" do
        patient = patients(:fernando)
        patient.update_attributes!(status: status)

        expect(patient.active?).to eq(true)
      end
    end
  end
end