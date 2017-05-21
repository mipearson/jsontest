#!/usr/bin/env ruby

require 'bundler/setup'
require 'oj'
require 'benchmark/ips'
require 'ruby-prof'

APP_PATH = File.expand_path('./config/application', __dir__)
JSON_FIXTURE = File.read('api_response.json')
JSON_OBJECT = Oj.load(JSON_FIXTURE)


Oj.mimic_JSON
require_relative './config/application'
Oj::Rails.set_encoder()
Oj::Rails.set_decoder()
Oj::Rails.optimize()
Oj::Rails.optimize(Hash)

TIMES=100

RubyProf.start
TIMES.times do
  # JSON_OBJECT.to_json
  Oj::Rails.encode(JSON_OBJECT)
end
result = RubyProf.stop


# print a graph profile to text
# printer = RubyProf::GraphHtmlPrinter.new(result)
printer = RubyProf::FlatPrinter.new(result)
printer.print(STDOUT, {})

