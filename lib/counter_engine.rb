require 'counter_engine/version'
require 'counter_engine/request'
require 'redis'
require 'securerandom'
require 'time'

class CounterEngine
  attr_reader :app, :redis
  attr_reader :stats_path

  DIVIDER = '|'

  def initialize(app,
                 redis_host: nil, redis_port: nil, redis_db: nil, redis_path: nil,
                 stats_path: nil)
    @app = app
    @redis = Redis.new(host: redis_host, port: redis_port, db: redis_db, path: redis_path)
    @stats_path = stats_path
  end

  def call(env)
    request = CounterEngine::Request.new(env)
    return show_stats(request) if stats_path && request.url == stats_path
    session_id = get_session_id(request)
    count_visit request, session_id
    process_request request
  end

  def show_stats(request)
    page = request.params['page']

    headers = { 'Content-Type' => 'application/json' }
    json = {
      unique: visits(page: page, unique: true),
      all: visits(page: page, unique: false)
    }.to_json
    [200, headers, [json]]
  end

  def visits(page: nil, unique: false, period: nil, period_type: :all)
    period = case period_type
            when :all
              :all
            else
              #TODO:
          end
    key = db_key(page, unique, period)
    if unique
      redis.scard(key)
    else
      redis.get(key).to_i
    end
  end

  private

  def get_session_id(request)
    request.remote_ip
  end

  def process_request(request)
    app.call request.env
  end

  def count_visit(request, session_id)
    url = request.url

    timestamp = Time.now

    periods = %w(all %Y %Y-%m %Y-%m-%d).map { |f| timestamp.strftime(f) }
    redis.pipelined do
      periods.each do |period|
        redis.incr db_key(nil, false, period)
        redis.incr db_key(url, false, period)
        redis.sadd db_key(nil, true, period), session_id
        redis.sadd db_key(url, true, period), session_id
      end
    end
  end

  def db_key(page, unique, period)
    key = page ? "pagevisits#{DIVIDER}#{page}" : 'sitevisits'
    "#{'unique' if unique}#{key}#{DIVIDER}#{period}"
  end
end
