# JSON Benchmarking

With:

  * Ruby JSON
  * YAJL
  * Oj
  * Oj in "Rails" mode
  * ActiveSupport::JSON

Created originally to determine why our JSON generation was taking 50 ms for 168kb of API response even though we were using Yajl, then refined to try to work out why `.to_json` was so slow.

Findings from below:

  * Rails "helpfully" replaces the `.to_json` methods on objects with ActiveSupport::JSON instead of Ruby's JSON.
  * I *should* be able to then use `Oj.add_to_json` to override this, but it isn't working, according to the benchmarks.
  * Omitting both YAJL and JSON from the loaded gems, and using `Oj.mimic_json` fixes `.to_json` performace (of course, this doesn't work with Rails, as it loads JSON for you)
  * `Oj.add_to_json` does not appear to be overriding `.to_json` even without Rails around
  * Ruby's native JSON generator is actually pretty fast! It's not as fast as Oj or Yajl, but it's much faster than I expected it to be.
  * `ActiveSupport::JSON` performance is terrible, and I really hope the Rails team find some way to get rid of it.
  * Using Ruby 2.4 instead of Ruby 2.3.1 does not appear to change the benchmarks significantly

## Environment

  * ruby 2.3.1p112 (2016-04-26 revision 54768) [x86_64-darwin14]
  * MacBook Pro (Retina, 13-inch, Mid 2014, 3Ghz Core i7)
  * Rails 5.1.1, oj 3.0.8, yajl-ruby 1.30

The JSON being encoded is representative of our of our larger, but very frequently accessed, public APIs used by our Javascript components.

## Without Rails

```
> ./benchmark_json.rb --rails
=== dumping ===
                      user     system      total        real
OJ:               1.090000   0.130000   1.220000 (  1.233473)
OJc:              1.380000   0.150000   1.530000 (  1.569449)
OJr:              1.360000   0.130000   1.490000 (  1.501414)
Yajl:             4.080000   0.180000   4.260000 (  4.277213)
JSON:             6.870000   0.110000   6.980000 (  7.011505)
to_json:          7.010000   0.120000   7.130000 (  7.174771)
JSON (mimic):     1.300000   0.120000   1.420000 (  1.440786)
to_json (mimic):  6.860000   0.210000   7.070000 (  7.093225)
to_json (Oj):     6.010000   0.100000   6.110000 (  6.133154)
```

## With Rails

```
> ./benchmark_json.rb --rails
Loading rails via ./config/application
=== dumping ===
                      user     system      total        real
OJ:               0.960000   0.100000   1.060000 (  1.069644)
OJc:              1.230000   0.120000   1.350000 (  1.346381)
OJr:             46.660000   0.420000  47.080000 ( 47.212316)
Yajl:             3.970000   0.110000   4.080000 (  4.084659)
JSON:             6.500000   0.110000   6.610000 (  6.636652)
to_json:         60.880000   0.330000  61.210000 ( 61.368512)
JSON (mimic):     1.250000   0.110000   1.360000 (  1.373204)
to_json (mimic): 27.120000   0.390000  27.510000 ( 27.576475)
to_json (rails): 24.840000   0.480000  25.320000 ( 25.387949)
```

Another run without the `Oj.mimic_JSON`, just in case that was confusing things:

```
./benchmark_json.rb --no-mimic --rails
Loading rails via ./config/application
=== dumping ===
                      user     system      total        real
OJ:               1.090000   0.100000   1.190000 (  1.192712)
OJc:              1.360000   0.120000   1.480000 (  1.484521)
OJr:             46.860000   0.420000  47.280000 ( 47.421344)
Yajl:             4.170000   0.170000   4.340000 (  4.350558)
JSON:             6.720000   0.110000   6.830000 (  6.845043)
to_json:         64.230000   0.340000  64.570000 ( 64.807216)
to_json (rails): 27.170000   0.310000  27.480000 ( 27.571227)
```

## Only using OJ (no JSON or Yajl gems)

```
> ./benchmark_json.rb --oj-only
=== dumping ===
                      user     system      total        real
OJ:               0.830000   0.080000   0.910000 (  0.908115)
OJc:              1.090000   0.080000   1.170000 (  1.175197)
OJr:              1.140000   0.100000   1.240000 (  1.248836)
JSON (mimic):     1.120000   0.110000   1.230000 (  1.237748)
to_json (mimic):  1.110000   0.110000   1.220000 (  1.220929)
to_json (Oj):     1.100000   0.100000   1.200000 (  1.204061)
```

## Using Ruby 2.4.0 (rather than 2.3.1, our production version)

```
> rbenv local 2.4.0
> ./benchmark_json.rb

=== dumping ===
                      user     system      total        real
OJ:               0.910000   0.100000   1.010000 (  1.005471)
OJc:              1.140000   0.110000   1.250000 (  1.257810)
OJr:              1.180000   0.110000   1.290000 (  1.294508)
Yajl:             3.740000   0.180000   3.920000 (  3.925623)
JSON:             5.600000   0.130000   5.730000 (  5.746722)
to_json:          5.660000   0.130000   5.790000 (  5.812608)
JSON (mimic):     1.090000   0.070000   1.160000 (  1.167717)
to_json (mimic):  5.710000   0.100000   5.810000 (  5.813098)
to_json (Oj):     5.580000   0.090000   5.670000 (  5.691292)

> ./benchmark_json --rails
Loading rails via ./config/application
=== dumping ===
                      user     system      total        real
OJ:               0.960000   0.110000   1.070000 (  1.093052)
OJc:              1.300000   0.130000   1.430000 (  1.429762)
OJr:             51.470000   0.570000  52.040000 ( 52.377774)
Yajl:             4.340000   0.200000   4.540000 (  4.577112)
JSON:             6.420000   0.130000   6.550000 (  6.579899)
to_json:         71.920000   0.510000  72.430000 ( 72.775430)
JSON (mimic):     1.290000   0.140000   1.430000 (  1.430857)
to_json (mimic): 31.670000   0.450000  32.120000 ( 32.554073)
to_json (rails): 27.310000   0.370000  27.680000 ( 27.792483)
```
