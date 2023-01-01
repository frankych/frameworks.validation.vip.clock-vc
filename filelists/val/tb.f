$ip/verif/tb/env/cdie_clk_vc_val_pkg.sv
$ip/verif/tb/cdie_clk_vc_tb.sv
$ip/verif/tb/sb_modules/gpsb_sideband_module.sv
$ip/verif/tb/sb_modules/pmsb_sideband_module.sv
+incdir+$UVM_HOME/src
+incdir+$ip/verif/tb
+incdir+$ip/verif/tests
+incdir+$ip/verif/tb/env
+incdir+$ip/verif/tb/seqlib
+incdir+$ip/verif/tb/seqlib/gpsb_sequences
+incdir+$ip/verif/tb/seqlib/pmsb_sequences
+incdir+$ip/verif/tb/sb_modules
#FIXME: This incdir is added because simple_tb_initial_block.sv has a line: `include "std_ace_util.vic"
#       If we don't need advanced FSDB dumping features implemented in this file - let's remove the `include.
#       If we do - I'd suggest storing this file in this repo (instead of having Ace pointers in this repo)
+incdir+/p/cth/rtl/proj_tools/ace/master/2.06.00/lib/Verilog
