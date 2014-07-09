class ApplicationController < ActionController::API

  rescue_from ActiveRecord::RecordNotFound do |exception|
    render_error(code: :not_found, message: "Not Found")
  end

  # TODO move this out of the controller into a separate file
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

  # TODO move this out of the controller into a responder class
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

end
