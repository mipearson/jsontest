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
  * Ruby's native JSON generator is actually pretty fast! It's not as fast as Oj or Yajl, but it's much faster than I expected it to be.
  * `ActiveSupport::JSON` performance is terrible, and I really hope the Rails team find some way to get rid of it.

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
