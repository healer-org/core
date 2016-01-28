class Client
  class << self
    def valid_key?(key)
      config[Rails.env] && config[Rails.env][:key] == key
    end

    private

    def config
      @config ||= YAML.load(File.read(config_path)).with_indifferent_access
    end

    def config_path
      File.join(Rails.root, "config", "clients.yml")
    end
  end
end
