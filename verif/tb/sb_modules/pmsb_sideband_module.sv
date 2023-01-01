// -------------------------------------------------------------------------------------------------
// INTEL TOP SECRET
// Copyright 2019 Intel Corporation
//
// This software and the related documents are Intel copyrighted materials, and your use of them
// is governed by the express license under which they were provided to you ("License"). Unless
// the License provides otherwise, you may not use, modify, copy, publish, distribute, disclose or
// transmit this software or the related documents without Intel's prior written permission.
//
// This software and the related documents are provided as is, with no express or implied
// warranties, other than those that are expressly stated in the License.
// -------------------------------------------------------------------------------------------------
`ifndef UVM_PKG_IMPORTED
`define UVM_PKG_IMPORTED
import uvm_pkg::*;
`endif

`include "uvm_macros.svh"

module pmsb_sideband_module(input logic clk, sideband_interface pmsb_agent_sideband_interface, sideband_interface pmsb_fabric_sideband_interface);
    svlib_uvm_pkg::VintfBundle vintfBundle;

    iosfsbm_cm_uvm::iosfsb_intf_wrapper #(.PAYLOAD_WIDTH(32), .IS_COMPMON(0), .AGENT_MASTERING_SB_IF(0)) Val_fabric_sideband_wrapper;
    iosfsbm_cm_uvm::iosfsb_intf_wrapper #(.PAYLOAD_WIDTH(32), .IS_COMPMON(0), .AGENT_MASTERING_SB_IF(1)) Val_agent_sideband_wrapper;    
    
    iosf_sbc_intf #(.PAYLOAD_WIDTH(32), .IS_COMPMON(0), .AGENT_MASTERING_SB_IF(0)) Val_pmsb_fabric_if (
        .side_clk(clk), 
        .side_rst_b(pmsb_fabric_sideband_interface.side_rst_b), 
        .gated_side_clk(), 
        .agent_rst_b(pmsb_fabric_sideband_interface.agent_rst_b)
    );

    iosf_sbc_intf #(.PAYLOAD_WIDTH(32), .IS_COMPMON(0), .AGENT_MASTERING_SB_IF(1)) Val_pmsb_agent_if (
        .side_clk(clk), 
        .side_rst_b(pmsb_agent_sideband_interface.side_rst_b), 
        .gated_side_clk(), 
        .agent_rst_b(pmsb_agent_sideband_interface.agent_rst_b)
    );

    initial begin : WRAPPERS_SETUP_AND_SHARE
        vintfBundle  = new("pmsb_vintfBundle");

        Val_fabric_sideband_wrapper = new(Val_pmsb_fabric_if);
        Val_agent_sideband_wrapper = new(Val_pmsb_agent_if);

        vintfBundle.setData("val_pmsb_fabric", Val_fabric_sideband_wrapper);
        vintfBundle.setData("val_pmsb_agent", Val_agent_sideband_wrapper);
        uvm_pkg::uvm_config_object::set(null, "pmsb_sideband_interface", svlib_uvm_pkg::SB_VINTF_BUNDLE_NAME, vintfBundle);

        uvm_config_db #(virtual sideband_interface)::set(null, "*", "pmsb_agent_sideband_interface", pmsb_agent_sideband_interface);
        uvm_config_db #(virtual sideband_interface)::set(null, "*", "pmsb_fabric_sideband_interface", pmsb_fabric_sideband_interface);
    end

    assign  Val_pmsb_fabric_if.side_ism_agent    = Val_pmsb_agent_if.side_ism_agent     ;
    assign  Val_pmsb_fabric_if.side_clkreq       = Val_pmsb_agent_if.side_clkreq        ;

    assign  Val_pmsb_fabric_if.tpcput            = Val_pmsb_agent_if.mpcput             ;
    assign  Val_pmsb_fabric_if.tnpput            = Val_pmsb_agent_if.mnpput             ;
    assign  Val_pmsb_fabric_if.tpayload          = Val_pmsb_agent_if.mpayload           ;
    assign  Val_pmsb_fabric_if.teom              = Val_pmsb_agent_if.meom               ;
    assign  Val_pmsb_fabric_if.mpccup            = Val_pmsb_agent_if.tpccup             ;
    assign  Val_pmsb_fabric_if.mnpcup            = Val_pmsb_agent_if.tnpcup             ;

    assign  Val_pmsb_agent_if.side_ism_fabric   = Val_pmsb_fabric_if.side_ism_fabric    ;
    assign  Val_pmsb_agent_if.side_clkack       = Val_pmsb_fabric_if.side_clkack        ;
    assign  Val_pmsb_agent_if.side_pok          = Val_pmsb_fabric_if.side_pok           ;

    assign  Val_pmsb_agent_if.tpcput            = Val_pmsb_fabric_if.mpcput             ;
    assign  Val_pmsb_agent_if.tnpput            = Val_pmsb_fabric_if.mnpput             ;
    assign  Val_pmsb_agent_if.tpayload          = Val_pmsb_fabric_if.mpayload           ;
    assign  Val_pmsb_agent_if.teom              = Val_pmsb_fabric_if.meom               ;
    assign  Val_pmsb_agent_if.mpccup            = Val_pmsb_fabric_if.tpccup             ;
    assign  Val_pmsb_agent_if.mnpcup            = Val_pmsb_fabric_if.tnpcup             ;
    
    assign pmsb_fabric_sideband_interface.agent_rst_b = pmsb_agent_sideband_interface.side_rst_b;
    assign pmsb_agent_sideband_interface.agent_rst_b = pmsb_fabric_sideband_interface.side_rst_b;
    
    assign Val_pmsb_fabric_if.fab_init_idle_exit_ack = 1'b1;

endmodule
