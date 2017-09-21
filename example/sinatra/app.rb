$:.unshift("#{__dir__}/../../lib")
require 'sinatra'
require 'counter_engine'

use CounterEngine, stats_path: '/stats.json'

get '/' do
  'root_url'
end

get '/foo' do
  'foo url'
end

get '/bar' do
  'bar url'
end