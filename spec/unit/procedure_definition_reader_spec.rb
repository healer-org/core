# frozen_string_literal: true

RSpec.describe V1::ProcedureDefinitionReader do
  describe "reading a config file" do
    it "reads a configuration file into JSON" do
      reader = V1::ProcedureDefinitionReader.new(
        :total_knee_replacement
      )

      def_keys = JSON.parse(reader.definition)["properties"].keys.map(&:to_sym)
      %i[sites implants].each do |key|
        expect(def_keys).to include(key)
      end
    end

    it "raises error if config definition is not present" do
      reader = V1::ProcedureDefinitionReader.new(:derp)

      expect { reader.definition[:input_values] }.to raise_error(V1::ProcedureDefinitionReader::ConfigNotFound)
    end
  end
end
