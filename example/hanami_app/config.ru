require './config/environment'

use CounterEngine, stats_path: '/stats.json'
run Hanami.app
