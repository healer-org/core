require "spec_helper"

describe Case do

  describe "#delete!" do
    before(:each) do
      @case = FactoryGirl.create(:case)
    end

    it "sets status value to 'deleted'" do
      @case.delete!

      @case.reload.status.should == "deleted"
    end

    it "logs the deletion" do
      Rails.logger.should_receive(:info).at_least(:once).with(
        "id=#{@case.id} object=Case action=delete"
      )

      @case.delete!
    end

    it "sends an event message"
  end

  describe "#active?" do
    it "is false if status is deleted" do
      a_case = FactoryGirl.create(:deleted_case)

      a_case.active?.should == false
    end

    %w(
      active
    ).each do |status|
      it "is true if status is #{status}" do
        a_case = FactoryGirl.create(:case)
        a_case.update_attributes!(status: status)

        a_case.active?.should == true
      end
    end
  end

end