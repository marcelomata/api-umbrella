require "rack"
require "rack/auth_proxy/authenticate"
require "rack/auth_proxy/authorize"
require "rack/auth_proxy/log"
require "rack/auth_proxy/throttle"
require "redis"

module AuthProxy
  class RackApp
    def self.redis_cache
      @@redis_cache ||= Redis.new
    end

    def self.instance
      @@instance ||= Rack::Builder.app do
        use Rack::AuthProxy::Log
        use Rack::AuthProxy::Authenticate
        use Rack::AuthProxy::Authorize
        use Rack::AuthProxy::Throttle::Daily,
          :cache => AuthProxy::RackApp.redis_cache,
          :max => 30000,
          :code => 503
        use Rack::AuthProxy::Throttle::Hourly,
          :cache => AuthProxy::RackApp.redis_cache,
          :max => 2000,
          :code => 503

        # Return a 200 OK status if all the middlewares pass through
        # successfully. This indicates to the calling AuthProxy::RequestHandler
        # that no errors have occurred processing the headers, and the
        # application can continue with a instruction to proxymachine.
        run lambda { |env| [200, {}, "OK"] }
      end
    end
  end
end
