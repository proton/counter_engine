require 'counter_engine/version'

class CounterEngine
  attr_reader :app

  def initialize(app, some_arg: nil)
    @app = app
  end

  def call(env)
    url = env['REQUEST_PATH']
    timestamp = Time.now
    ip = env['REMOTE_ADDR']
    p [url, timestamp, ip]
    app.call env
  end
end
