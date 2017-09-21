class CounterEngine
  class Request
    attr_reader :env

    def initialize(env)
      @env = env
    end

    def url
      env['PATH_INFO']
    end

    def remote_ip
      env['REMOTE_ADDR']
    end

    def params
      @get_params ||= begin
        Hash[env['QUERY_STRING'].split('&').map { |s| s.split('=') }]
      end
    end

    def cookies
      @cookies ||= begin
        Hash[env['HTTP_COOKIE'].to_s.split('; ').map { |s| s.split('=') }]
      end
    end
  end
end
