class ApplicationController < ActionController::API
  BAD_REQUESTS = [
    ActiveRecord::RecordInvalid,
    ActionController::ParameterMissing,
    Errors::MismatchedPatient
  ]

  after_filter :set_access_control_headers

  rescue_from ActiveRecord::RecordNotFound do |exception|
    render_error(code: :not_found, message: "Not Found")
  end

  rescue_from *BAD_REQUESTS do |exception|
    render_error(code: :bad_request, message: exception.message)
  end

  def render_error(code: nil, message: nil)
    raise ArgumentError unless code

    code ||= :not_found
    data = { :http_code => Rack::Utils.status_code(code) }
    data[:message] = message if message

    # logger.error(response)
    render(
      json: Response.new(:data => data, :root => "error"),
      status: code
    )
  end


  private

  def set_access_control_headers
    return unless Rails.env == "development"
    headers["Access-Control-Allow-Origin"] = "*"
    headers["Access-Control-Request-Method"] = "*"
  end

end

class Response

  def initialize(data: {}, root: nil)#, pagination: nil)
    @data = data
    @root = root
    # @pagination = pagination
  end

  def to_json(options = {})
    body = if @data
      @root.present? ? { @root => @data } : @data
    end

    # if body && body.is_a?(Hash)
    #   if @pagination
    #     body[:pagination] = @pagination
    #   elsif @data.respond_to?(:current_page)
    #     body[:pagination] = { :page => @data.current_page, :perPage => @data.per_page, :total => @data.total_entries }
    #   end
    # end

    body ? body.to_json : ""
  end

end
