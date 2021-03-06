require "addressable/uri"
require "httparty"

module LinkshareAPI
  # For implementation details please visit
  # http://helpcenter.linkshare.com/publisher/questions.php?questionid=652
  class ProductSearch
    include HTTParty

    attr_reader :api_base_url, :api_timeout, :keyword, :token

    def initialize
      @token        = LinkshareAPI.token
      @api_base_url = LinkshareAPI::WEB_SERVICE_URIS[:product_search]
      @api_timeout  = LinkshareAPI.api_timeout

      if @token.nil?
        raise AuthenticationError.new(
          "No token. Set your token by using 'LinkshareAPI.token = <TOKEN>'. " +
          "You can retrieve your token from LinkhShare's Web Services page under the Links tab. " +
          "See http://helpcenter.linkshare.com/publisher/questions.php?questionid=648 for details."
        )
      end
    end

    def query(params)
      raise ArgumentError, "Hash expected, got #{params.class} instead" unless params.is_a?(Hash)

      params.merge!(token: token)
      begin
        response = self.class.get(
          api_base_url,
          query: params,
          timeout: api_timeout
        )
      rescue Timeout::Error
        raise ConnectionError.new("Timeout error (#{timeout}s)")
      end

      if response.code != 200
        raise Error.new(response.message, response.code)
      end
      error = response["result"]["Errors"]
      raise InvalidRequestError.new(error["ErrorText"], error["ErrorID"].to_i) if error

      Response.new(response)
    end
  end
end
