class V1::PatientPresenter < V1::BasePresenter

  def initialize(patient_attributes)
    @patient_attributes = HashWithIndifferentAccess.new(patient_attributes)
  end

  def present
    {}.tap do |presented|
      presented[:id] = patient_attributes[:id]
      presented[:name] = patient_attributes[:name]
      presented[:gender] = patient_attributes[:gender]
      presented[:birth] = patient_attributes[:birth]
      presented[:death] = patient_attributes[:death]

      if patient_attributes[:cases]
        presented[:cases] =
          patient_attributes[:cases].map do |c|
            {
              id: c[:id],
              anatomy: c[:anatomy],
              side: c[:side]
            }
        end
      end

    end
  end


  private

  attr_reader :patient_attributes

end