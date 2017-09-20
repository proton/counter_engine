require 'sinatra'
require 'counter_engine'

# use Rack::Cache do
#   set :verbose, true
#   set :metastore,   'heap:/'
#   set :entitystore, 'heap:/'
# end

# before do
#   last_modified $updated_at ||= Time.now
# end

get '/' do
  'root_url'
end

get '/foo' do
  'foo url'
end

get '/bar' do
  'bar url'
end