package cdie_clk_vc_val_pkg;
    import uvm_pkg::*;
    import iosfsbm_cm_uvm::*;
    import iosfsbm_uvm_seq::*;
    import cdie_clk_vc_env_pkg::*;
   
    `include "uvm_macros.svh"
    
    `include "pmsb_txn_seqlib.sv"
    `include "base_gpsb_sequence.sv"
    `include "dvfs_send_wp_seq.sv"
    `include "mailbox_cr_write_seq.sv"
    `include "gpsb_reg_read_sequence.sv"
    `include "gpsb_reg_write_sequence.sv"
    `include "send_cbo_drain_msg_sequence.sv"
    `include "send_cmpd_msg_sequence.sv"
    `include "send_ncu_pcu_msg_sequence.sv"
    `include "cdie_sideband_watcher.sv"
    `include "cdie_svid_ownership_semaphore_cb.sv"
    `include "cdie_clk_vc_val_env.sv"    
endpackage
