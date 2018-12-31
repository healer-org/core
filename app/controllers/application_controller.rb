class ApplicationController < ActionController::API
  BAD_REQUESTS = [
    "ActionController::BadRequest",
    "ActiveRecord::RecordInvalid",
    "ActionController::ParameterMissing",
    "Errors::MismatchedPatient"
  ].freeze

  NOT_FOUND_REQUESTS = [
    "ActiveRecord::RecordNotFound"
  ].freeze

  after_action :set_dev_access_control_headers, if: -> { Rails.env == "development" }

  rescue_from(*NOT_FOUND_REQUESTS) do
    render_error(code: :not_found, message: "Not Found")
  end

  rescue_from(*BAD_REQUESTS) do |exception|
    render_error(code: :bad_request, message: exception.message)
  end

  def render_error(code: nil, message: nil)
    raise ArgumentError unless code

    code ||= :not_found
    data = { http_code: Rack::Utils.status_code(code) }
    data[:message] = message if message

    # logger.error(response)
    render(
      json: Response.new(data: data, root: "error"),
      status: code
    )
  end

  def routing_error
    # handles ActionController::RoutingError directed from routes
    render_error(code: :not_found, message: "Not Found")
  end

  private

  def set_dev_access_control_headers
    headers["Access-Control-Allow-Origin"] = "*"
    headers["Access-Control-Request-Method"] = "*"
  end
end

class Response
  def initialize(data: {}, root: nil) # , pagination: nil)
    @data = data
    @root = root
    # @pagination = pagination
  end

  def to_json(*)
    if data
      (root.present? ? { root => data } : data).to_json
    else
      ""
    end
  end

  private

  attr_reader :data, :root
end
