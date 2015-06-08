RSpec.describe Procedure do
  fixtures :cases

  def valid_attributes
    {
      case: cases(:fernando_left_hip),
      date: Date.today
    }
  end

  def valid_attributes_without(key)
    valid_attributes.reject{ |k,v| k == key }
  end

  describe "validates" do
    it "case is required" do
      expect{
        Procedure.create(valid_attributes_without(:case))
      }.to_not change(Procedure, :count)
    end
    it "date is required" do
      expect{
        Procedure.create(valid_attributes_without(:date))
      }.to_not change(Procedure, :count)
    end
  end
end