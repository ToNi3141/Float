PROJ = float

all: sub mul itf

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

itf:
	verilator -CFLAGS -std=c++11 -Wno-lint -Wno-style -Wno-fatal --cc -exe ../rtl/float/IntToFloat.v --top-module IntToFloat sim_IntToFloat.cpp -I../rtl/float/
	make -C obj_dir -f VIntToFloat.mk
	./obj_dir/VIntToFloat

sim: my_design
	vvp my_design

my_design:
	iverilog -o my_design ../rtl/float/FloatAdd.v

.SECONDARY:
.PHONY: all clean
