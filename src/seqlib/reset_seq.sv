import "DPI-C" context task cdie_pydoh_drive_local_half_bridge_rst(int value);

class send_simple_txn_dmu_to_punit extends uvm_sequence;
    `uvm_object_utils(send_simple_txn_dmu_to_punit)

    iosfsbm_cm_uvm::iosfsbc_sequencer sb_sequencer;
    cdie_pm_vc_config cdie_pm_config;
    rand logic [7:0] opcode;

    function new(string name="");
        super.new(name);
        if(!uvm_config_db#(cdie_pm_vc_config)::get(null, "", "cdie_pm_vc_config", cdie_pm_config))
            `uvm_fatal(get_type_name(), "Unable to get cdie_pm_vc_config from uvm_config_db");
        if(!uvm_config_db#(iosfsbm_cm_uvm::iosfsbc_sequencer)::get(null, "cdie_pm_vc_env", "cdie_pm_vc_pmsb_sequencer", sb_sequencer)) begin
            `uvm_fatal("cdie_sb_from_py_port", $psprintf("Could not get sequencer in scope cdie_pm_vc_pmsb_sequencer from config DB"));  
        end
    endfunction

    virtual task body();
        iosfsbm_cm_uvm::simple_xaction simple_txn;
        logic [7:0] dest_svc_pid, src_svc_pid;
        logic [7:0] extended_headers[4] = '{8'h00, cdie_pm_config.punit_to_dmu_sai, 8'h00, 8'h00};

        simple_txn = iosfsbm_cm_uvm::simple_xaction::type_id::create("simple_txn", null);
        simple_txn.set_cfg(sb_sequencer.get_ep_cfg(), sb_sequencer.get_common_cfg());
        
        if (sb_sequencer.m_ep_cfg.global_intf_en == 1) begin
            dest_svc_pid = cdie_pm_config.punit_pmsb_portid[15:8];
            src_svc_pid = cdie_pm_config.dmu_pmsb_portid[15:8];
        end else begin
            dest_svc_pid = cdie_pm_config.punit_pmsb_portid[7:0];
            src_svc_pid = cdie_pm_config.dmu_pmsb_portid[7:0];
        end

        if(!simple_txn.randomize() with {
                    foreach(extended_headers[i])
                    ext_headers_per_txn[i] == extended_headers[i];
                    ext_headers_per_txn.size() == extended_headers.size();
                    EH == 1'b1;
                    opcode == local::opcode;
                    dest_pid == dest_svc_pid;
                    local_dest_pid == cdie_pm_config.punit_pmsb_portid[7:0];
                    src_pid == src_svc_pid;
                    local_src_pid == cdie_pm_config.dmu_pmsb_portid[7:0];
                    xaction_class == iosfsbm_cm_uvm::POSTED;
                })
            `uvm_fatal(get_type_name(), "Could not randomize transaction object")
        simple_txn.set_sequencer(sb_sequencer);
        `uvm_send(simple_txn)
    endtask
endclass

class cdie_drive_half_bridge_rst_seq extends uvm_sequence;

    `uvm_object_utils(cdie_drive_half_bridge_rst_seq)

    rand bit value;
    static bit driving_signals = 0;

    virtual cdie_pm_vc_if cdie_pm_vc_vif;

    constraint qreqn_c{
        soft value == cdie_pm_vc_vif.local_half_bridge_rst_b_async;
    }

    function new(string name="");
        super.new(name);
        if(!uvm_config_db #(virtual cdie_pm_vc_if)::get(null, "*", "cdie_pm_vc_if", cdie_pm_vc_vif))
            `uvm_fatal(get_type_name(), "Unable to find the cdie virtual interface in the uvm_config_db")
    endfunction

    virtual task body();
        wait (driving_signals == 0);
        driving_signals = 1;
        fork
            cdie_pydoh_drive_local_half_bridge_rst(value);
        join_none
        #1ns;
        driving_signals = 0;
    endtask

endclass
