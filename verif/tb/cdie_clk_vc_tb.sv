`include "sideband_interface.sv"

module cdie_clk_vc_tb();
    reg clk;
  `ifndef MY_CLK_PERIOD
   `define MY_CLK_PERIOD 100
  `endif

   `include "simple_clk.sv"
   `include "simple_tb_initial_block.sv"
   
    sideband_interface agent_gpsb_sideband_interface();
    sideband_interface fabric_gpsb_sideband_interface();
    sideband_interface agent_pmsb_sideband_interface();
    sideband_interface fabric_pmsb_sideband_interface();
    cdie_clk_vc_if cdie_clk_vc_if();
    cdie_clk_vc_dielet_pm_if cdie_gpsb_dielet_pm_if();
    cdie_clk_vc_dielet_pm_if cdie_pmsb_dielet_pm_if();
    cdie_clk_vc_dielet_pm_if cdie_idi_dielet_pm_if();

    // start uvm_test
    initial uvm_pkg::run_test();

    // test island
    cdie_clk_vc_ti cdie_clk_vc_ti(cdie_clk_vc_if, cdie_gpsb_dielet_pm_if, cdie_pmsb_dielet_pm_if, cdie_idi_dielet_pm_if);
    gpsb_sideband_module gpsb_sideband_inst(clk, agent_gpsb_sideband_interface, fabric_gpsb_sideband_interface);
    pmsb_sideband_module pmsb_sideband_inst(clk, agent_pmsb_sideband_interface, fabric_pmsb_sideband_interface);

    assign cdie_clk_vc_if.local_half_bridge_clk = clk;
endmodule

`include "cdie_clk_vc_base_test.sv"
`include "cdie_clk_vc_doa_test.sv"
`include "cdie_clk_vc_sb_test.sv"
`include "cdie_clk_vc_cold_boot_test.sv"
`include "cdie_clk_vc_pkgc_test.sv"
`include "cdie_clk_vc_warm_reset_test.sv"
`include "cdie_clk_vc_sx_test.sv"
`include "cdie_clk_vc_global_reset_test.sv"
`include "cdie_clk_vc_cold_reset_test.sv"
`include "cdie_clk_vc_dc_base_test.sv"
`include "cdie_clk_vc_dc1_test.sv"
`include "cdie_clk_vc_dc6_test.sv"
`include "cdie_clk_vc_dc6_popup_test.sv"
`include "cdie_clk_vc_dc3_abort_test.sv"
`include "cdie_clk_vc_dc3_popup_test.sv"
`include "cdie_clk_vc_dc3_test.sv"
`include "cdie_clk_vc_warm_reset_pkgc_test.sv"
`include "cdie_clk_vc_dvfs_test.sv"
`include "cdie_clk_vc_cr_access_test.sv"
`include "cdie_clk_vc_cbo_response_test.sv"
`include "cdie_clk_vc_user_svid_test.sv"
`include "cdie_clk_vc_svid_generator_test.sv"


