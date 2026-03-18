require "test_helper"

class LegacySessionCookieBridgeTest < ActiveSupport::TestCase
  class EchoApp
    def call(env)
      [ 200, { "Content-Type" => "text/plain" }, [ env["HTTP_COOKIE"].to_s ] ]
    end
  end

  test "bridges the legacy cookie to the new key and sets the new cookie" do
    middleware = Middleware::LegacySessionCookieBridge.new(
      EchoApp.new,
      old_key: "_poor_man_session",
      new_key: "_stovaro_session"
    )

    env = Rack::MockRequest.env_for(
      "/",
      "HTTP_COOKIE" => "_poor_man_session=legacy-token",
      "rack.url_scheme" => "https"
    )

    status, headers, body = middleware.call(env)
    set_cookie = headers["Set-Cookie"] || headers["set-cookie"]

    assert_equal 200, status
    assert_includes body.join, "_poor_man_session=legacy-token"
    assert_includes body.join, "_stovaro_session=legacy-token"
    assert_includes set_cookie, "_stovaro_session=legacy-token"
    assert_includes set_cookie, "secure"
  end

  test "does not duplicate the cookie when the new key already exists" do
    middleware = Middleware::LegacySessionCookieBridge.new(
      EchoApp.new,
      old_key: "_poor_man_session",
      new_key: "_stovaro_session"
    )

    env = Rack::MockRequest.env_for(
      "/",
      "HTTP_COOKIE" => "_poor_man_session=legacy-token; _stovaro_session=current-token"
    )

    status, headers, body = middleware.call(env)

    assert_equal 200, status
    assert_equal "_poor_man_session=legacy-token; _stovaro_session=current-token", body.join
    assert_nil headers["Set-Cookie"]
  end
end
