module CustomMatchers
  def appointment_response_matches?(response, record)
    response_and_record_match?(
      response,
      record,
      APPOINTMENT_ATTRIBUTES,
      time: %i(start end)
    )
  end

  def patient_response_matches?(response, record)
    response_and_record_match?(
      response,
      record,
      PATIENT_ATTRIBUTES,
      date: %i(birth)
    )
  end

  def case_response_matches?(response, record)
    response_and_record_match?(
      response,
      record,
      CASE_ATTRIBUTES
    )
  end

  def attachment_response_matches?(response, record)
    response_and_record_match?(
      response,
      record,
      ATTACHMENT_ATTRIBUTES,
      time: %i(created_at)
    )
  end

  # rubocop:disable Metrics/AbcSize
  def response_and_record_match?(response, record, attributes, custom_types = {})
    attributes.all? do |attr|
      value = response[attr.to_s.camelize(:lower)]
      if custom_types[:time] && custom_types[:time].include?(attr)
        expect(Time.parse(value).iso8601).to eq(record.send(attr).iso8601)
      elsif custom_types[:date] && custom_types[:date].include?(attr)
        expect(value).to eq(record.send(attr).to_s(:db))
      else
        expect(value.to_s).to eq(record.send(attr).to_s)
      end
    end
  end
  # rubocop:enable Metrics/AbcSize
end
