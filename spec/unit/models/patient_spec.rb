require "spec_helper"

describe Patient do
  fixtures :patients, :cases

  describe "#delete!" do
    before(:each) do
      @patient = patients(:silvia)
    end

    it "sets status value to 'deleted'" do
      @patient.delete!

      @patient.reload.status.should == "deleted"
    end

    it "deletes all attached cases" do
      case_1 = cases(:silvia_left_foot)
      case_2 = cases(:silvia_right_foot)

      case_1.active?.should == true
      case_2.active?.should == true

      @patient.delete!

      case_1.reload.active?.should == false
      case_2.reload.active?.should == false
    end

    it "does not swallow errors if case fails to be deleted" do
      case_1 = cases(:silvia_left_foot)

      Case.any_instance.stub(:delete!).and_raise "Fail"

      expect { @patient.delete! }.to raise_error
    end

    it "does not delete patient case fails to be deleted" do
      case_1 = cases(:silvia_left_foot)

      Case.any_instance.stub(:delete!).and_raise "Fail"

      expect { @patient.delete! }.to raise_error

      @patient.reload.active?.should == true
    end

    it "logs the deletion" do
      Rails.logger.stub(:info)
      Rails.logger.should_receive(:info).at_least(:once).with(
        "id=#{@patient.id} object=Patient action=delete"
      )

      @patient.delete!
    end

    it "sends an event message"
  end

  describe "#active?" do
    it "is false if status is deleted" do
      patient = patients(:deleted)

      patient.active?.should == false
    end

    %w(
      active
    ).each do |status|
      it "is true if status is #{status}" do
        patient = patients(:fernando)
        patient.update_attributes!(status: status)

        patient.active?.should == true
      end
    end
  end
end