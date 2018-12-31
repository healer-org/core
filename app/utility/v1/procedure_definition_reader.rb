# frozen_string_literal: true

module V1
  class ProcedureDefinitionReader
    class ConfigNotFound < StandardError; end

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
      raise ConfigNotFound unless File.exist?(config_file_path)

      YAML.safe_load(
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
