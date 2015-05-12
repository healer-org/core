class Client
  class << self
    def valid_key?(key)
      config[Rails.env] && config[Rails.env][:key] == key
    end

    private

    def config
      @config ||= YAML.load(File.read(File.join(
                    Rails.root, "config", "clients.yml"))
                  ).with_indifferent_access
    end
  end
end