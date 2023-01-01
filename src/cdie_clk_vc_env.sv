import "DPI-C" context task cdie_load_gpsb_cr_data(int portid, int address, longint unsigned data);
import "DPI-C" context task cdie_load_pmsb_cr_data(int portid, int address, longint unsigned data);
import "DPI-C" context task cdie_load_gpsb_mem_data(int address, longint unsigned data);
import "DPI-C" context task cdie_load_pmsb_mem_data(int address, longint unsigned data);
import "DPI-C" context task cdie_power_state_response_handler_set_min_state(int state);
import "DPI-C" context task cdie_power_state_response_handler_set_max_state(int state);
import "DPI-C" context task cdie_power_state_response_handler_set_ack_state(int ack);

import sv_pydoh_infra_env_pkg::*;

class cdie_pm_vc_env extends uvm_env;

    `uvm_component_utils(cdie_pm_vc_env)

    iosfsbm_cm_uvm::iosf_sb_vc gpsb_vc;
    iosfsbm_cm_uvm::iosf_sb_vc pmsb_vc;
    sb_to_py_port gpsb_to_py_port, pmsb_to_py_port;
    sb_from_py_port gpsb_from_py_port, pmsb_from_py_port;
    run_control_port cdie_run_control;
    config_file_writer config_writer;
    cdie_pm_vc_config cdie_pm_config;
    uvm_analysis_export#(iosfsbm_cm_uvm::xaction) cdie_gpsb_analysis_export, cdie_pmsb_analysis_export;
    string py_port_prefix = "";
    string pmsb_to_py_name = "cdie_pmsb_py_port";
    string gpsb_to_py_name = "cdie_gpsb_py_port";

    function new(string name, uvm_component parent);
        super.new(name, parent);
        cdie_pm_config = new("cdie_pm_vc_config");
        uvm_config_db#(cdie_pm_vc_config)::set(null, "", "cdie_pm_vc_config", cdie_pm_config);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (cdie_pm_config.vc_ep_is_global == 1)
            py_port_prefix = "global_";
        gpsb_to_py_port = sb_to_py_port::type_id::create({py_port_prefix, gpsb_to_py_name}, this);
        pmsb_to_py_port = sb_to_py_port::type_id::create({py_port_prefix, pmsb_to_py_name}, this);
        cdie_gpsb_analysis_export = new("cdie_gpsb_analysis_export");
        cdie_pmsb_analysis_export = new("cdie_pmsb_analysis_export");
        gpsb_from_py_port = sb_from_py_port::type_id::create("cdie_gpsb_from_py_port");
        pmsb_from_py_port = sb_from_py_port::type_id::create("cdie_pmsb_from_py_port");
        config_writer = new("config_file_writer");
        config_writer.init_file("cdie_pm_vc_config_raw.yaml");
        cdie_run_control = run_control_port::type_id::create("cdie_run_control", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        cdie_gpsb_analysis_export.connect(gpsb_to_py_port.sideband_input_fifo.analysis_export);
        cdie_pmsb_analysis_export.connect(pmsb_to_py_port.sideband_input_fifo.analysis_export);
        gpsb_from_py_port.set_scope_name({py_port_prefix, gpsb_to_py_name});
        pmsb_from_py_port.set_scope_name({py_port_prefix, pmsb_to_py_name});
    endfunction

    function void set_gpsb_vc(iosfsbm_cm_uvm::iosf_sb_vc vc);
        gpsb_vc = vc;
    endfunction

    function void set_pmsb_vc(iosfsbm_cm_uvm::iosf_sb_vc vc);
        pmsb_vc = vc;
    endfunction

    function void start_of_simulation_phase(uvm_phase phase);
        super.start_of_simulation_phase(phase);
        gpsb_to_py_port.set_dest_portid(cdie_pm_config.dmu_gpsb_portid);
        gpsb_to_py_port.set_dest_portid(cdie_pm_config.cdie_ncevents_gpsb_portid);
        gpsb_to_py_port.set_dest_portid(cdie_pm_config.cdie_ccf_multicast_portid);
        gpsb_to_py_port.set_dest_portid(cdie_pm_config.cdie_ccf_pma_portid);
        gpsb_to_py_port.set_dest_portid(cdie_pm_config.cdie_ncracu_gpsb_portid);
        foreach(cdie_pm_config.cdie_cbo_portids[i])
            gpsb_to_py_port.set_dest_portid(cdie_pm_config.cdie_cbo_portids[i]);
        
        pmsb_to_py_port.set_dest_portid(cdie_pm_config.dmu_pmsb_portid);
        if (gpsb_vc == null)
            `uvm_fatal(get_type_name(), "GPSB VC has not been set.");
        if (pmsb_vc == null)
            `uvm_fatal(get_type_name(), "PMSB VC has not been set.");
        uvm_config_db#(iosfsbm_cm_uvm::iosfsbc_sequencer)::set(null, "cdie_pm_vc_env", "cdie_pm_vc_gpsb_sequencer", gpsb_vc.get_sequencer());
        uvm_config_db#(iosfsbm_cm_uvm::iosfsbc_sequencer)::set(null, "cdie_pm_vc_env", "cdie_pm_vc_pmsb_sequencer", pmsb_vc.get_sequencer());
        gpsb_from_py_port.set_vc_sequencer(gpsb_vc.get_sequencer());
        pmsb_from_py_port.set_vc_sequencer(pmsb_vc.get_sequencer());
        config_writer.write_config_to_file_raw(cdie_pm_config);
        config_writer.close_file();
    endfunction

    task power_state_response_handler_set_min_state(logic [15:0] state);
        fork begin
            wait_for_pydoh_to_be_initialized();
            cdie_power_state_response_handler_set_min_state(state);
        end join_none
    endtask
    
    task power_state_response_handler_set_max_state(logic [15:0] state);
        fork begin
            wait_for_pydoh_to_be_initialized();
            cdie_power_state_response_handler_set_max_state(state);
        end join_none
    endtask
    
    task power_state_response_handler_set_ack_state(logic ack);
        fork begin
            wait_for_pydoh_to_be_initialized();
            cdie_power_state_response_handler_set_ack_state(ack);
        end join_none
    endtask

    task load_gpsb_cr_data(logic [15:0] portid, logic [15:0] address, logic [63:0] data);
        fork begin
            wait_for_pydoh_to_be_initialized();
            cdie_load_gpsb_cr_data(portid[7:0], address, data);
        end join_none
    endtask

    task load_pmsb_cr_data(logic [15:0] portid, logic [15:0] address, logic [63:0] data);
        fork begin
            wait_for_pydoh_to_be_initialized();
            cdie_load_pmsb_cr_data(portid[7:0], address, data);
        end join_none
    endtask

    task load_gpsb_mem_data(logic [15:0] address, logic [63:0] data);
        fork begin
            wait_for_pydoh_to_be_initialized();
            cdie_load_gpsb_mem_data(address, data);
        end join_none
    endtask

    task load_pmsb_mem_data(logic [15:0] address, logic [63:0] data);
        fork begin
            wait_for_pydoh_to_be_initialized();
            cdie_load_pmsb_mem_data(address, data);
        end join_none
    endtask

    task wait_for_pydoh_to_be_initialized();
        uvm_event pydoh_initialized;
        if(!uvm_config_db#(uvm_event)::get(null, "", "pydoh_initialization_event", pydoh_initialized))
            `uvm_fatal(get_type_name(), "Pydoh initialization event was never registered to config_db");

        pydoh_initialized.wait_on();
        #1;
    endtask

endclass
