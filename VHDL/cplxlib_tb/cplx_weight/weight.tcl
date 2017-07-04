# Typically ALDEC Riviera-Pro reports the installation path with the variable $aldec

set TOOLPATH $aldec

if ![file exists $TOOLPATH] {
  error "Tool path not found. Please provide path to compiler/simulator."
}

# library path
set LIBROOT ../..

set TEST_LIB "work"
vlib $TEST_LIB

# ALTERA library path
#  set ALTERA_LIB $TOOLPATH/vlib/altera_16v0
set ALTERA_LIB $TOOLPATH/vlib/altera_14v1

# XILINX library path
set XILINX_LIB $TOOLPATH/vlib/xilinx_16v4

source $LIBROOT/baselib/_compile_1993.tcl
source $LIBROOT/dsplib/_compile_1993.tcl
# source $LIBROOT/dsplib/stratixv/_compile.tcl
# source $LIBROOT/dsplib/ultrascale/_compile.tcl
source $LIBROOT/dsplib/behave/_compile.tcl
source $LIBROOT/cplxlib/_compile_1993.tcl

vcom -93 -explicit -dbg -work $TEST_LIB $LIBROOT/cplxlib_tb/cplx_stimuli.vhdl
vcom -93 -explicit -dbg -work $TEST_LIB $LIBROOT/cplxlib_tb/cplx_logger.vhdl
vcom -93 -explicit -dbg -work $TEST_LIB weight_tb.vhdl

# get read access to all signals
vsim +access +r weight_tb

# waveforms
do weight.do

run -all
