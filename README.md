# Float

Small float library with configurable mantissa and exponent.
Goal was to use as less clock cycles as possible, have pipelining (one calculation per clock) and still get a reasonable clock frequency. It runs on Artix 7 devices with around 100MHz.

## Facts
- Implemented operations: ```*```, ```+```, ```-```, ```1/x```, ```int to float```, ```float to int```
- Also implements a fixed point recip `XRecip`. Does not really belong to here, but it was convenient to implement it here, because all required code was already here.
- __One operation per clock__ (all operations are __pipelined__)
- Latency: __4 Clock cycles__ (except FloatRecip which requires 11)
- FloatFastRecip to get a fast approximation for ```1/x``` (error is around 5%). It is a very small and fast implementation
- FloatRecip to get a 100% accurate approximation of ```1/x``` with floats using a 23 bit mantissa, but at the cost of utilization and delay. It uses the newton method to approximate ```1/x```.
- IEEE 754 compatible but not compliant
- All IEEE 754 formats are supported like: half (s=1, e=5, m=10), single (s=1, e=8, m=23), double (s=1, e=11, m=52), ...

# Usage
Just use the files in ```rtl/float/```. Copy them or use this repo as a sub repo in your project.