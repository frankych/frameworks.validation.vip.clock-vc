// only use uvm and saola for simulation activities
// (including variants like emulation-simulation and fpga-simulation)
import uvm_pkg::*;
import sv_pydoh_infra_env_pkg::*;
import cdie_clk_vc_env_pkg::*;

`include "uvm_macros.svh"

import "DPI-C" context function void start_python_interpreter();
import "DPI-C" context function void start_pydoh_agents();
import "DPI-C" context function void cdie_add_pydoh_paths();
import "DPI-C" context function void initialize_cdie_vc();

module cdie_clk_vc_ti(cdie_clk_vc_if cdie_clk_vc_if, cdie_clk_vc_dielet_pm_if cdie_gpsb_dielet_pm_if, cdie_clk_vc_dielet_pm_if cdie_pmsb_dielet_pm_if, cdie_clk_vc_dielet_pm_if cdie_idi_dielet_pm_if);

    uvm_event pydoh_initialized;
	initial begin
        pydoh_initialized = new();
        if (!uvm_config_db #(uvm_event)::get(null, "*", "pydoh_initialization_event", pydoh_initialized)) begin
            uvm_config_db #(uvm_event)::set(null, "", "pydoh_initialization_event", pydoh_initialized);
            start_python_interpreter();
            #1;
            cdie_add_pydoh_paths();
            start_pydoh_agents();
            #1;            
            pydoh_initialized.trigger;
        end else begin
            cdie_add_pydoh_paths();
            #2; 
        end
        initialize_cdie_vc();
    end
    initial begin
        uvm_config_db #(virtual cdie_clk_vc_if)::set(null, "*", "cdie_clk_vc_if", cdie_clk_vc_if);
        uvm_config_db #(virtual cdie_clk_vc_dielet_pm_if)::set(null, "*", "cdie_gpsb_dielet_pm_if", cdie_gpsb_dielet_pm_if);
        uvm_config_db #(virtual cdie_clk_vc_dielet_pm_if)::set(null, "*", "cdie_pmsb_dielet_pm_if", cdie_pmsb_dielet_pm_if);
        uvm_config_db #(virtual cdie_clk_vc_dielet_pm_if)::set(null, "*", "cdie_idi_dielet_pm_if", cdie_idi_dielet_pm_if);
    end

   `include "common_dpi_functions.sv"


endmodule
