#!/usr/bin/env ruby

require 'bundler/setup'
require 'oj'
require 'benchmark/ips'

APP_PATH = File.expand_path('./config/application', __dir__)
JSON_FIXTURE = File.read('api_response.json')
JSON_OBJECT = Oj.load(JSON_FIXTURE)
CSV_FILE = "out.csv"

args = ARGV.join(' ')
puts "Run with: #{args}"

csv = ARGV.delete("--csv")
quick = ARGV.delete("--quick")
oj_mimic_json = ARGV.delete("--oj-mimic-json")
require_json = ARGV.delete("--require-json")
require_json_after_mimic = ARGV.delete("--require-json-after-mimic")
use_rails = ARGV.delete("--use-rails")
oj_optimize_rails = ARGV.delete("--oj-optimize-rails")
oj_optimize_rails_hash = ARGV.delete("--oj-optimize-rails-hash")
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
if oj_optimize_rails_hash
  Oj::Rails.optimize(Hash)
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

bench = Benchmark.ips() do |x|
  if quick
    # Used for smoke-testing only
    x.config(time: 1, warmup: 1)
  else
    x.config(time: 20, warmup: 3)
  end

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

if csv
  require 'csv'
  first_entry = bench.entries.shift
  baseline = first_entry.microseconds / first_entry.iterations

  out = ["'" + args.gsub("--csv", ""), sprintf("%0.2f", baseline / 1000)]

  bench.entries.each do |entry|
    speed = entry.microseconds / entry.iterations
    times = speed / baseline
    out << sprintf("%0.2f", times)
    out << sprintf("%0.2f", speed / 1000)
  end

  File.open(CSV_FILE, "a+") do |f|
    f.puts out.to_csv
  end
end

