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
    request.remote_ip
  end

  def process_request(request)
    app.call request.env
  end

  def count_visit(request, session_id)
    url = request.url

    timestamp = Time.now

    # Итак, у нас есть некий visit pages
      # он пустой:
    # first_site_visit = first_page_visit = true
      # он полный, но без url:
    # first_site_visit = false; first_page_visit = true
      # он полный и с url:
    # first_site_visit = first_page_visit = false

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
