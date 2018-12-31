# https://scotch.io/tutorials/build-a-restful-json-api-with-rails-5-part-three
class ApiVersion
  attr_reader :version, :default

  def initialize(version, default = false)
    @version = version
    @default = default
  end

  # check whether version is specified or is default
  def matches?(request)
    check_headers(request.headers) || default
  end

  private

  def check_headers(headers)
    # check version from Accept headers; expect custom media type `healer`
    accept = headers[:accept]
    accept && accept.include?("application/vnd.healer-api.#{version}+json")
  end
end
