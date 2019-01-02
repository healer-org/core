# frozen_string_literal: true

class Procedure < Base
  belongs_to :appointment
  belongs_to :case

  store_accessor :data,
                 :date,
                 :providers,
                 :sites,
                 :title,
                 :type,
                 :version

  validates :case, presence: true
  validates :type, presence: true
  validates :version, presence: true
  # validate :providers_correctly_formatted
  validate :conforms_to_definition

  def method_missing(method_name, *args)
    if data.respond_to?(method_name)
      data.send(method_name, *args)
    else
      super
    end
  end

  def respond_to_missing?(method_name, _include_private = false)
    data.respond_to?(method_name)
  end

  private

  # def providers_correctly_formatted
  #   errors.add(:providers, "are malformed") unless providers.is_a?(Hash)
  # end

  def conforms_to_definition
    JSON::Validator.fully_validate(
      definition, data, errors_as_objects: true
    ).each do |error|
      errors.add(error[:fragment], error[:message])
    end
  end

  def definition
    # inline rescue is to alleviate missing type, which is responsible for
    # determining which definition to use. maybe raise after_initialize instead?
    @definition ||= definition_reader_for(type)
  end

  def definition_reader_for(type)
    V1::ProcedureDefinitionReader.new(type.to_sym).definition
  rescue StandardError
    {}.to_json
  end
end
