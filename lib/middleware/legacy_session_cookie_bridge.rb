module Middleware
  class LegacySessionCookieBridge
    def initialize(app, old_key:, new_key:)
      @app = app
      @old_key = old_key
      @new_key = new_key
    end

    def call(env)
      old_value = cookie_value(env["HTTP_COOKIE"], @old_key)
      new_value = cookie_value(env["HTTP_COOKIE"], @new_key)

      if old_value && new_value.nil?
        env["HTTP_COOKIE"] = append_cookie(env["HTTP_COOKIE"], @new_key, old_value)
      end

      status, headers, body = @app.call(env)

      if old_value && new_value.nil?
        Rack::Utils.set_cookie_header!(
          headers,
          @new_key,
          value: old_value,
          path: "/",
          httponly: true,
          same_site: :lax,
          secure: ssl_request?(env)
        )
      end

      [ status, headers, body ]
    end

    private

    def cookie_value(header, key)
      Rack::Utils.parse_cookies_header(header.to_s)[key]
    end

    def append_cookie(header, key, value)
      parts = []
      parts << header unless header.nil? || header.empty?
      parts << "#{key}=#{value}"
      parts.join("; ")
    end

    def ssl_request?(env)
      env["HTTPS"].to_s == "on" || env["rack.url_scheme"].to_s == "https"
    end
  end
end
