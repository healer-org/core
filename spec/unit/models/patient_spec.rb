require "spec_helper"

describe Patient do

  describe "#delete!" do
    before(:each) do
      @patient = FactoryGirl.create(:patient)
    end

    it "sets status value to 'deleted'" do
      @patient.delete!

      @patient.reload.status.should == "deleted"
    end

    it "deletes all attached cases" do
      case_1 = FactoryGirl.create(:active_case, patient: @patient)
      case_2 = FactoryGirl.create(:active_case, patient: @patient)

      case_1.active?.should == true
      case_2.active?.should == true

      @patient.delete!

      case_1.reload.active?.should == false
      case_2.reload.active?.should == false
    end

    it "does not swallow errors if case fails to be deleted" do
      case_1 = FactoryGirl.create(:active_case, patient: @patient)

      Case.any_instance.stub(:delete!).and_raise "Fail"

      expect { @patient.delete! }.to raise_error
    end

    it "does not delete patient case fails to be deleted" do
      case_1 = FactoryGirl.create(:active_case, patient: @patient)

      Case.any_instance.stub(:delete!).and_raise "Fail"

      expect { @patient.delete! }.to raise_error

      @patient.reload.active?.should == true
    end

    it "logs the deletion" do
      Rails.logger.should_receive(:info).at_least(:once).with(
        "id=#{@patient.id} object=Patient action=delete"
      )

      @patient.delete!
    end

    it "sends an event message"
  end

  describe "#active?" do
    it "is false if status is deleted" do
      patient = FactoryGirl.create(:deleted_patient)

      patient.active?.should == false
    end

    %w(
      active
    ).each do |status|
      it "is true if status is #{status}" do
        patient = FactoryGirl.create(:patient)
        patient.update_attributes!(status: status)

        patient.active?.should == true
      end
    end
  end
end