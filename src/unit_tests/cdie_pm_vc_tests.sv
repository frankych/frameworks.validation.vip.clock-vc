//import uvm_pkg::*;
//`include "uvm_macros.svh"
//`include "vunit.svh"
//
//package iosfsbm_agent_uvm;
//    class iosfsbm_agtvc;        
//    endclass
//endpackage
//
//package iosfsbm_cm_uvm;        
//    class iosfsbc_sequencer;
//    endclass
//    class iosf_sb_vc;
//        function iosfsbc_sequencer get_sequencer();            
//        endfunction
//    endclass
//    class xaction;
//    endclass
//    
//endpackage
//
//class cold_boot_responder extends uvm_component;
//    `uvm_component_utils(cold_boot_responder)
//    function new(string name, uvm_component parent);
//        super.new(name, parent);
//    endfunction    
//endclass
//`include "cdie_pm_vc_defs.sv"
//`include "cdie_sb_to_py_port.sv"
//`include "cdie_pm_vc_env.sv"
//
//class TF_cdie_pm_vc extends vunit::Fixture;
//
//    cdie_pm_vc_env cut; // REPLACE cut with something interesting
//   
//    function new();       
//           
//    endfunction
//   
//    virtual task setup();
//       cut = cdie_pm_vc_env::type_id::create("cut", null);
//    endtask
//    
//    virtual task teardown();
//
//    endtask
//    
//endclass
//      
//`TESTSUITE_F(TF_cdie_pm_vc, cdie_pm_vc_testsuite)
//
//    `TEST_F(TF_cdie_pm_vc, can_instantiate_cut)
//        `ASSERT_NOTNULL(cut);
//    `ENDTEST
//
//`ENDTESTSUITE
