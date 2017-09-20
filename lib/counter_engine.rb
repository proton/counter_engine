require 'counter_engine/version'
require 'redis'
# require 'securerandom'

class CounterEngine
  attr_reader :app, :redis
  attr_reader :uniq_detection_by, :cookie_expires_in, :cookie_name

  COOKIE_NEVER_EXPIRES = Time.parse('9999-12-31')

  def initialize(app,
                 redis_host: nil, redis_port: nil, redis_db: nil, redis_path: nil,
                 uniq_detection_by: :cookie, cookie_expires_in: nil, cookie_name: '__counter_engine_session_id')
    @app = app
    @redis = Redis.new(host: redis_host, port: redis_port, db: redis_db, path: redis_path)
    @uniq_detection_by = uniq_detection_by
    @cookie_expires_in = cookie_expires_in
    @cookie_name = cookie_name
  end

  def call(env)
    session_id = get_session_id(env)
    count_visit env, session_id
    process_request env, session_id
  end

  private

  def get_session_id(env)
    case uniq_detection_by
      when :cookie
        # TODO:
        p env['HTTP_COOKIE']
        'aaa'
      when :ip
        env['REMOTE_ADDR']
    end
  end

  def cookie_expires_time
    return COOKIE_NEVER_EXPIRES unless cookie_expires_in
    Time.now + cookie_expires_in
  end

  def process_request(env, session_id)
    r = app.call env
    first_visit = true #???
    return r unless first_visit && uniq_detection_by == :cookie
    # set cookie & responce
    status, headers, body = r
    response = Rack::Response.new body, status, headers
    expires_time = cookie_expires_time
    response.set_cookie(cookie_name, { value: 1, path: '/', expires: expires_time })
    response.finish
  end

  def count_visit(env, session_id)
    url = env['REQUEST_PATH']

    # add
    # increment site_visits_month
    # increment page_visits_month
    # increment site_visits_day
    # increment page_visits_day

    # add to set page_uniq_visits_month ???
    # add visited pages to set

    url = env['REQUEST_PATH']
    timestamp = Time.now
    ip = env['REMOTE_ADDR']
    p [url, timestamp, ip]
  end
end
