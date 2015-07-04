class ProcedureSerializer
  def self.dump(hash)
    hash.to_json
  end

  def self.load(hash)
    Hashie::Mash.new((hash || {}).with_indifferent_access)
  end
end