require 'counter_engine/version'
require 'counter_engine/request'
require 'redis'
require 'securerandom'
require 'time'

class CounterEngine
  attr_reader :app, :redis
  attr_reader :uniq_detection_by, :cookie_expires_in, :cookie_name
  attr_reader :stats_path

  COOKIE_NEVER_EXPIRES = Time.parse('9999-12-31')
  DIVIDER = '|'

  def initialize(app,
                 redis_host: nil, redis_port: nil, redis_db: nil, redis_path: nil,
                 uniq_detection_by: :cookie, cookie_expires_in: nil, cookie_name: '__counter_engine_session_id',
                 stats_path: nil)
    @app = app
    @redis = Redis.new(host: redis_host, port: redis_port, db: redis_db, path: redis_path)
    @uniq_detection_by = uniq_detection_by
    @cookie_expires_in = cookie_expires_in
    @cookie_name = cookie_name
    @stats_path = stats_path
  end

  def call(env)
    request = CounterEngine::Request.new(env)
    return show_stats(request) if stats_path && request.url == stats_path
    session_id, need_cookie = get_session_id(request)
    count_visit request, session_id
    process_request request, session_id, need_cookie
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
    key = page ? "pagevisit#{DIVIDER}#{page}" : 'sitevisit'
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

  def get_session_id(request)
    need_new_cookie = false
    case uniq_detection_by
      when :cookie
        session_id = request.cookies[cookie_name]
        unless session_id
          session_id = SecureRandom.uuid + '-' + Time.now.to_i.to_s(36)
          need_new_cookie = true
        end
      when :ip
        session_id = request.remote_ip
    end
    [session_id, need_new_cookie]
  end

  def cookie_expires_time
    return COOKIE_NEVER_EXPIRES unless cookie_expires_in
    Time.now + cookie_expires_in
  end

  def process_request(request, session_id, need_cookie)
    env = request.env
    r = app.call env
    return r unless need_cookie
    status, headers, body = r
    response = Rack::Response.new body, status, headers
    expires_time = cookie_expires_time
    response.set_cookie(cookie_name, { value: session_id, path: '/', expires: expires_time })
    response.finish
  end

  def count_visit(request, session_id)
    url = request.url

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
