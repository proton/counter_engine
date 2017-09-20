$:.unshift("#{__dir__}/../../lib")
require 'sinatra'
require 'counter_engine'

use CounterEngine, some_arg: 123

get '/' do
  'root_url'
end

get '/foo' do
  'foo url'
end

get '/bar' do
  'bar url'
end