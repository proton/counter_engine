require 'counter_engine/version'

class CounterEngine
  def initialize
    #
  end

  def call(env)
    [200, {'Content-Type' => 'text/html'}, ENV.inspect]
  end
end
