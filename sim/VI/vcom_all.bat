vcom -93 -quiet -work  sim/mem ^
../system/src/mem/dpram.vhd ^
../system/src/mem/RamMLAB.vhd ^
../../rtl/SyncFifo.vhd ^
../../rtl/SyncFifoFallThrough.vhd ^
../../rtl/SyncFifoFallThroughMLAB.vhd ^
../../rtl/SyncRam.vhd

vcom -2008 -quiet -work sim/n64 ^
../../rtl/functions.vhd ^
../../rtl/VI_package.vhd ^
../../rtl/VI_overlay.vhd ^
../../rtl/VI_videoout_sync.vhd ^
../../rtl/VI_linefetch.vhd ^
../../rtl/VI_lineProcess.vhd ^
../../rtl/VI_filter_pen.vhd ^
../../rtl/VI_filter.vhd ^
../../rtl/VI_gammatable.vhd ^
../../rtl/VI_outProcess.vhd ^
../../rtl/VI_videoout.vhd ^
../../rtl/VI.vhd ^
../../rtl/SDRamMux.vhd ^
../../rtl/DDR3Mux.vhd

vcom -2008 -quiet -work sim/tb ^
../system/src/tb/globals.vhd ^
../system/src/tb/ddrram_model.vhd ^
../system/src/tb/sdram_model.vhd ^
../system/src/tb/framebuffer.vhd ^
../system/src/tb/tb_savestates.vhd ^
src/tb/tb.vhd

