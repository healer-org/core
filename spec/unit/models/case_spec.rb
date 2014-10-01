require "spec_helper"

describe Case do
  fixtures :cases

  describe "#delete!" do
    before(:each) do
      @case = cases(:fernando_left_hip)
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
      a_case = cases(:fernando_deleted_right_knee)

      a_case.active?.should == false
    end

    %w(
      active
    ).each do |status|
      it "is true if status is #{status}" do
        a_case = cases(:fernando_left_hip)
        a_case.update_attributes!(status: status)

        a_case.active?.should == true
      end
    end
  end

end