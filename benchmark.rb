#!/usr/bin/env ruby

require 'bundler/setup'
require 'oj'
require 'benchmark/ips'

APP_PATH = File.expand_path('./config/application', __dir__)
JSON_FIXTURE = File.read('api_response.json')
JSON_OBJECT = Oj.load(JSON_FIXTURE)

puts "Run with: #{ARGV.sort.join(' ')}"

quick = ARGV.delete("--quick")
oj_mimic_json = ARGV.delete("--mimic-json")
require_json = ARGV.delete("--require-json")
require_json_after_mimic = ARGV.delete("--require-json-after-mimic")
use_rails = ARGV.delete("--use-rails")
oj_optimize_rails = ARGV.delete("--oj-optimize-rails")
oj_manual_set_encoder = ARGV.delete("--oj-manual-set-encoder")

if ARGV.length > 0
  raise "Unknown ARGS #{ARGV.inspect}"
end

require_relative './config/application' if use_rails
require 'json' if require_json
Oj.mimic_JSON if oj_mimic_json
require 'json' if require_json_after_mimic
if oj_optimize_rails
  Oj::Rails.set_encoder()
  Oj::Rails.set_decoder()
  Oj::Rails.optimize()
end

if oj_manual_set_encoder
  # as per https://precompile.com/2015/07/25/rails-activesupport-json.html
  module ActiveSupport::JSON::Encoding
    class Oj < JSONGemEncoder
      def encode value
        ::Oj.dump(value.as_json)
      end
    end
  end
  ActiveSupport.json_encoder = ActiveSupport::JSON::Encoding::Oj
end

Benchmark.ips() do |x|
  x.config(time: 1, warmup: 1) if quick # Used for smoke-testing only

  x.report("Oj.dump(X, :object)") { Oj.dump(JSON_OBJECT, mode: :object) }
  x.report("Oj::Rails.encode(X)") { Oj::Rails.encode(JSON_OBJECT) }

  if require_json || oj_mimic_json || use_rails
    x.report("JSON.dump(X)") { JSON.dump(JSON_OBJECT) }
    x.report("X.to_json") { JSON_OBJECT.to_json }
  end
  if use_rails
    x.report("AS::JSON.encode(X)") { ActiveSupport::JSON.encode(JSON_OBJECT)}
    x.report("X.as_json") { JSON_OBJECT.as_json }
  end
  x.compare!
end
