PROJ = float

all: sub mul itf fti inv recip

clean:
	rm -R obj_dir

sub:
	verilator -CFLAGS -std=c++11 --cc -exe ../rtl/float/FloatSub.v --top-module FloatSub sim_FloatSub.cpp -I../rtl/float/
	make -C obj_dir -f VFloatSub.mk
	./obj_dir/VFloatSub 

mul:
	verilator -CFLAGS -std=c++11 --cc -exe ../rtl/float/FloatMul.v --top-module FloatMul sim_FloatMul.cpp -I../rtl/float/
	make -C obj_dir -f VFloatMul.mk
	./obj_dir/VFloatMul

itf:
	verilator -CFLAGS -std=c++11 --cc -exe ../rtl/float/IntToFloat.v --top-module IntToFloat sim_IntToFloat.cpp -I../rtl/float/
	make -C obj_dir -f VIntToFloat.mk
	./obj_dir/VIntToFloat

fti:
	verilator -CFLAGS -std=c++11 --cc -exe ../rtl/float/FloatToInt.v --top-module FloatToInt sim_FloatToInt.cpp -I../rtl/float/
	make -C obj_dir -f VFloatToInt.mk
	./obj_dir/VFloatToInt

inv:
	verilator -CFLAGS -std=c++11 --cc -exe ../rtl/float/FloatFastRecip.v --top-module FloatFastRecip sim_FloatFastRecip.cpp -I../rtl/float/
	make -C obj_dir -f VFloatFastRecip.mk
	./obj_dir/VFloatFastRecip

recip:
	verilator -CFLAGS -std=c++11 --cc -exe ../rtl/float/FloatRecip.v --top-module FloatRecip sim_FloatRecip.cpp -I../rtl/float/
	make -C obj_dir -f VFloatRecip.mk
	./obj_dir/VFloatRecip

xrecip:
	verilator -CFLAGS -std=c++11 --cc -exe ../rtl/float/XRecip.v --top-module XRecip sim_XRecip.cpp -I../rtl/float/
	make -C obj_dir -f VXRecip.mk
	./obj_dir/VXRecip

sim: my_design
	vvp my_design

my_design:
	iverilog -o my_design ../rtl/float/FloatAdd.v

.SECONDARY:
.PHONY: all clean
