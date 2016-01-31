module V1
  class ProcedureDefinitionReader
    attr_reader :definition

    def initialize(definition_name)
      @definition_name = definition_name.to_sym
    end

    def definition
      # TODO: memoization might not be necessary here
      @definition ||= read_definition.to_json
    end

    private

    def read_definition
      fail "config not found" unless File.exist?(config_file_path)

      YAML.load(
        File.read(config_file_path)
      ).deep_symbolize_keys![definition_name]
    end

    attr_reader :definition_name

    def config_file_path
      File.join(
        Rails.root,
        "config",
        "definitions",
        "procedures",
        "v1",
        "#{definition_name}.yml"
      )
    end
  end
end
