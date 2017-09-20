require 'counter_engine/version'
require 'redis'
require 'securerandom'

class CounterEngine
  attr_reader :app, :redis
  attr_reader :uniq_detection_by, :cookie_expires_in, :cookie_name

  COOKIE_NEVER_EXPIRES = Time.parse('9999-12-31')
  DIVIDER = '|'

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
    session_id, need_cookie = get_session_id(env)
    count_visit env, session_id
    process_request env, session_id, need_cookie
  end

  def visits(page: nil, unique: false, period: nil, period_type: :all)
    key = page ? "pagevisit#{DIVIDER}#{url}" : 'sitevisit'
    key = "unique#{key}" if unique
    per = case period_type
            when :all
              :all
            else
              #TODO:
          end
    key = "#{key}#{DIVIDER}#{per}"
    redis.get(key).to_i
  end

  private

  def get_session_id(env)
    case uniq_detection_by
      when :cookie
        # Какой-то временный кэш по ip в redis, чтобы избежать одновременных запросов?
        regex = /#{cookie_name}=(.+?);/
        m = env['HTTP_COOKIE'].to_s.match(regex)
        return [m[1], false] if m
        session_id = SecureRandom.uuid + '-' + Time.now.to_i.to_s(36)
        [session_id, true]
      when :ip
        [env['REMOTE_ADDR'], false]
    end
  end

  def cookie_expires_time
    return COOKIE_NEVER_EXPIRES unless cookie_expires_in
    Time.now + cookie_expires_in
  end

  def process_request(env, session_id, need_cookie)
    r = app.call env
    return r unless need_cookie
    status, headers, body = r
    response = Rack::Response.new body, status, headers
    expires_time = cookie_expires_time
    response.set_cookie(cookie_name, { value: session_id, path: '/', expires: expires_time })
    response.finish
  end

  def count_visit(env, session_id)
    url = env['REQUEST_PATH']

    timestamp = Time.now

    # set first_visit_ts

    # create session if nil
    # add page to set
    # set first visit
    first_site_visit = true
    first_page_visit = false

    keys = %w(all %Y %Y-%m %Y-%m-%d).map { |f| timestamp.strftime(f) }
    redis.pipelined do
      keys.each do |key|
        increment_count "sitevisit#{DIVIDER}#{key}"
        increment_count "pagevisit#{DIVIDER}#{url}#{DIVIDER}#{key}"
        increment_count "uniqsitevisit#{DIVIDER}#{key}" if first_site_visit
        increment_count "uniqpagevisit#{DIVIDER}#{url}#{DIVIDER}#{key}" if first_page_visit
      end
    end
  end

  def increment_count(key)
    redis.incr key
  end
end
