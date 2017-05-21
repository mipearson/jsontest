#!/bin/sh

set -e

rm -f out.csv
bundle exec ruby ./benchmark.rb --csv --require-json
bundle exec ruby ./benchmark.rb --csv --require-json --oj-mimic-json
bundle exec ruby ./benchmark.rb --csv --require-json-after-mimic --oj-mimic-json

bundle exec ruby ./benchmark.rb --csv --use-rails
bundle exec ruby ./benchmark.rb --csv --use-rails --oj-mimic-json
bundle exec ruby ./benchmark.rb --csv --use-rails --oj-optimize-rails
bundle exec ruby ./benchmark.rb --csv --use-rails --oj-optimize-rails --oj-mimic-json
bundle exec ruby ./benchmark.rb --csv --use-rails --oj-manual-set-encoder
bundle exec ruby ./benchmark.rb --csv --use-rails --oj-manual-set-encoder --oj-optimize-rails
bundle exec ruby ./benchmark.rb --csv --use-rails --oj-manual-set-encoder --oj-optimize-rails --oj-mimic-json

