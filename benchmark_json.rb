#!/usr/bin/env ruby

APP_PATH = File.expand_path('./config/application', __dir__)

use_rails = ARGV.include?('--rails')

if use_rails
  require_relative './config/application'
  require 'yajl'
  require 'benchmark'

  puts 'Loading rails via ./config/application'
else
  require 'bundler/setup'
  require 'json'
  require 'oj'
  require 'benchmark'
  require 'yajl'
end

str = File.read('api_response.json')
obj = JSON.parse(str)

n = 1000

puts '=== dumping ==='
Benchmark.bm(15) do |x|
  x.report('OJ:') { n.times { Oj.dump(obj) } }
  x.report('OJc:') { n.times { Oj.dump(obj, mode: :compat) } }
  x.report('OJr:') { n.times { Oj.dump(obj, mode: :rails) } }
  x.report('Yajl:')   { n.times { Yajl.dump(obj)   } }
  x.report('JSON:')   { n.times { JSON.dump(obj) } }
  x.report('to_json:') { n.times { obj.to_json } }

  Oj.mimic_JSON
  x.report('JSON (mimic):') { n.times { JSON.dump(obj) } }
  x.report('to_json (mimic):') { n.times { obj.to_json } }

  if use_rails
    Oj.optimize_rails
    Oj.add_to_json
    x.report('to_json (rails):') { n.times { obj.to_json } }
  end
end
