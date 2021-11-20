PROJ = float

all: sub mul

clean:
	rm -R obj_dir

sub:
	verilator -CFLAGS -std=c++11 -Wno-lint -Wno-style -Wno-fatal --cc -exe ../rtl/float/FloatSub.v --top-module FloatSub sim_FloatSub.cpp -I../rtl/float/
	make -C obj_dir -f VFloatSub.mk
	./obj_dir/VFloatSub 

mul:
	verilator -CFLAGS -std=c++11 -Wno-lint -Wno-style -Wno-fatal --cc -exe ../rtl/float/FloatMul.v --top-module FloatMul sim_FloatMul.cpp -I../rtl/float/
	make -C obj_dir -f VFloatMul.mk
	./obj_dir/VFloatMul

sim: my_design
	vvp my_design

my_design:
	iverilog -o my_design ../rtl/float/FloatAdd.v

.SECONDARY:
.PHONY: all clean
