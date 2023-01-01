`include "cdie_pm_vc_if.sv"
`include "cdie_pm_vc_dielet_pm_if.sv"

package cdie_pm_vc_env_pkg;
    import uvm_pkg::*;
    import iosfsbm_cm_uvm::*;
    import iosfsbm_agent_uvm::*;
    import iosfsbm_uvm_seq::*;
   `include "uvm_macros.svh"

   `include "cdie_pm_vc_defs.sv"
   `include "cdie_pm_vc_config.sv"
   `include "config_file_writer.sv"
   `include "pkgc_seq.sv"
   `include "svid_seq.sv"
   `include "send_power_info_seq.sv"
   `include "reset_seq.sv"
   `include "cdie_pm_vc_env.sv"   
   `include "cdie_pm_start_boot_flow_seq.sv"
  
endpackage
