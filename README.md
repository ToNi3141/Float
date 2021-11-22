# Float

Small float library with configurable mantissa and exponent.
Goal was to use as less clock cycles as possible and still get a reasonable performance. It should be possible to synthesize it on an iCE40UP5k and still achieve a frequency of 24MHz (by configure it as single precision IEEE 754 float).

## Facts
- Implemented operations: ```*```, ```+```, ```-```, ```1/x```, ```int to float```, ```float to int```
- __One operation per clock__ (all operations are __pipelined__)
- Latency: __4 Clock cycles__ (except FloatFastRecip2 which requires 12)
- FloatFastRecip to get a fast approximation for ```1/x``` (error is around 5%)
- FloatFastRecip2 to get a more accurate approximation for ```1/x``` but at the cost of utilization and delay (error is around 0.01%)
- IEEE 754 compatible but not compliant
- All IEEE 754 formats are supported like: half (s=1, e=5, m=10), single (s=1, e=8, m=23), double (s=1, e=11, m=52), ...

# Usage
Just use the files in ```rtl/float/```. Copy them or use this repo as a sub repo in your project.