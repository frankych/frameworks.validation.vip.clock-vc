import "DPI-C" context task cdie_pydoh_drive_sb_signals(int pmsb_qreqn, int gpsb_qreqn, int idi_qreqn, int pmsb_iso_req_b, int gpsb_iso_req_b, int idi_iso_req_b, int coherent_traffic_req, int thermtripout, int prochot_indication);

import "DPI-C" context task cdie_set_target_state(string state);

class cdie_set_target_power_state extends uvm_sequence;
    
    rand cdie_cstate_t state;
    
    virtual task body();
        cdie_set_target_state($sformatf("%s", state));
    endtask
    
endclass

class send_regio_txn_dmu_to_punit extends uvm_sequence;
    `uvm_object_utils(send_regio_txn_dmu_to_punit)

    iosfsbm_cm_uvm::iosfsbc_sequencer sb_sequencer;
    cdie_pm_vc_config cdie_pm_config;
    rand logic [15:0] register_addr;
    rand logic [31:0] register_data;

    function new(string name="");
        super.new(name);
        if(!uvm_config_db#(cdie_pm_vc_config)::get(null, "", "cdie_pm_vc_config", cdie_pm_config))
            `uvm_fatal(get_type_name(), "Unable to get cdie_pm_vc_config from uvm_config_db");
        if(!uvm_config_db#(iosfsbm_cm_uvm::iosfsbc_sequencer)::get(null, "cdie_pm_vc_env", "cdie_pm_vc_pmsb_sequencer", sb_sequencer)) begin
            `uvm_fatal("cdie_sb_from_py_port", $psprintf("Could not get sequencer with scope cdie_pm_vc_pmsb_sequencer from config DB"));
        end
    endfunction

    virtual task body();
        iosfsbm_cm_uvm::regio_xaction reg_write_txn;
        logic [7:0] dest_svc_pid, src_svc_pid;
        logic [7:0] data_array [4];
        logic [7:0] addr_array [2];
        logic [7:0] extended_headers[4] = '{8'h00, cdie_pm_config.punit_to_dmu_sai, 8'h00, 8'h00};

        addr_array = '{register_addr[7:0], register_addr[15:8]};
        data_array = '{register_data[7:0], register_data[15:8], register_data[23:16], register_data[31:24]};

        reg_write_txn = iosfsbm_cm_uvm::regio_xaction::type_id::create("reg_write_txn", null);
        reg_write_txn.set_cfg(sb_sequencer.get_ep_cfg(), sb_sequencer.get_common_cfg());

        if (sb_sequencer.m_ep_cfg.global_intf_en == 1) begin
            dest_svc_pid = cdie_pm_config.punit_pmsb_portid[15:8];
            src_svc_pid = cdie_pm_config.dmu_pmsb_portid[15:8];
        end else begin
            dest_svc_pid = cdie_pm_config.punit_pmsb_portid[7:0];
            src_svc_pid = cdie_pm_config.dmu_pmsb_portid[7:0];
        end

        if(!reg_write_txn.randomize() with {
                    foreach(addr_array[i])
                    addr[i] == addr_array[i];
                    foreach(data_array[i])
                    data[i] == data_array[i];
                    data.size() == data_array.size();
                    addr.size() == addr_array.size();
                    foreach(extended_headers[i])
                    ext_headers_per_txn[i] == extended_headers[i];
                    ext_headers_per_txn.size() == extended_headers.size();
                    EH == 1'b1;
                    sbe == 4'h0;
                    fbe == 4'hf;
                    fid == 'h0;
                    opcode == iosfsbm_cm_uvm::OP_CRWR;
                    dest_pid == dest_svc_pid;
                    local_dest_pid == cdie_pm_config.punit_pmsb_portid[7:0];
                    src_pid == src_svc_pid;
                    local_src_pid == cdie_pm_config.dmu_pmsb_portid[7:0];
                    xaction_class == iosfsbm_cm_uvm::POSTED;
                })
            `uvm_fatal(get_type_name(), "Could not randomize transaction object")
        reg_write_txn.set_sequencer(sb_sequencer);
        `uvm_send(reg_write_txn)
    endtask
endclass


class cdie_send_wish_power_state extends uvm_sequence;
    `uvm_object_utils(cdie_send_wish_power_state)

    rand cdie_cstate_t wish_state;
    cdie_pm_vc_config cdie_pm_config;

    function new(string name="");
        super.new(name);
        if(!uvm_config_db#(cdie_pm_vc_config)::get(null, "", "cdie_pm_vc_config", cdie_pm_config))
            `uvm_fatal(get_type_name(), "Unable to get cdie_pm_vc_config from uvm_config_db");
    endfunction

    virtual task body();
        send_regio_txn_dmu_to_punit reg_write_seq = new();
        if(!reg_write_seq.randomize() with {
                    register_addr == cdie_pm_config.wish_power_state_cdie2soc_addr;
                    register_data == {8'h0, 8'h0, 8'h0, wish_state };
                })
            `uvm_fatal(get_type_name(), "Could not randomize transaction object")
        reg_write_seq.start(null);
    endtask
endclass


class cdie_send_power_state_response extends uvm_sequence;
    `uvm_object_utils(cdie_send_power_state_response)

    rand cdie_cstate_t max_state, min_state;
    rand bit ack;
    cdie_pm_vc_config cdie_pm_config;

    constraint ps_response_const {
        soft ack == 1'b1;
        max_state >= min_state;
    }

    function new(string name="");
        super.new(name);
        if(!uvm_config_db#(cdie_pm_vc_config)::get(null, "", "cdie_pm_vc_config", cdie_pm_config))
            `uvm_fatal(get_type_name(), "Unable to get cdie_pm_vc_config from uvm_config_db");
    endfunction

    virtual task body();
        send_regio_txn_dmu_to_punit reg_write_seq = new();
        logic [7:0] ack_indication = {7'h0, ack};
        if(!reg_write_seq.randomize() with {
                    register_addr == cdie_pm_config.power_state_rsp_cdie2soc_addr;
                    register_data == {8'h0, ack_indication, min_state, max_state};
                })
            `uvm_fatal(get_type_name(), "Could not randomize transaction object")
        reg_write_seq.start(null);
    endtask

endclass

class cdie_send_opmode_status extends uvm_sequence;
    `uvm_object_utils(cdie_send_opmode_status)

    rand core_op_mode_t core_mode;
    rand ccf_op_mode_t ccf_mode;
    rand fabric_op_mode_t fabric_mode;
    cdie_pm_vc_config cdie_pm_config;

    function new(string name="");
        super.new(name);
        if(!uvm_config_db#(cdie_pm_vc_config)::get(null, "", "cdie_pm_vc_config", cdie_pm_config))
            `uvm_fatal(get_type_name(), "Unable to get cdie_pm_vc_config from uvm_config_db");
    endfunction

    virtual task body();
        send_regio_txn_dmu_to_punit reg_write_seq = new();
        if(!reg_write_seq.randomize() with {
                    register_addr == cdie_pm_config.resource_operating_mode_status_cdie2soc_addr;
                    register_data == {8'h0, fabric_mode, ccf_mode, core_mode};
                })
            `uvm_fatal(get_type_name(), "Could not randomize transaction object")
        reg_write_seq.start(null);
    endtask
endclass

class cdie_send_op_mode_valid extends uvm_sequence;

    `uvm_object_utils(cdie_send_op_mode_valid)

    cdie_pm_vc_config cdie_pm_config;

    function new(string name="");
        super.new(name);
        if(!uvm_config_db#(cdie_pm_vc_config)::get(null, "", "cdie_pm_vc_config", cdie_pm_config))
            `uvm_fatal(get_type_name(), "Unable to get cdie_pm_vc_config from uvm_config_db");
    endfunction

    virtual task body();
        send_regio_txn_dmu_to_punit reg_write_seq = new();
        if(!reg_write_seq.randomize() with {
                    register_addr == cdie_pm_config.resource_operating_mode_status_valid_cdie2soc_addr;
                    register_data == {8'h0, 8'h0, 8'h0, 8'h1}; //reg contains only one field, 'valid' at bit0
                })
            `uvm_fatal(get_type_name(), "Could not randomize transaction object")
        reg_write_seq.start(null);
    endtask

endclass

class cdie_send_diec_current_state extends uvm_sequence;

    `uvm_object_utils(cdie_send_diec_current_state)

    rand cdie_cstate_t current_state;
    cdie_pm_vc_config cdie_pm_config;

    function new(string name="");
        super.new(name);
        if(!uvm_config_db#(cdie_pm_vc_config)::get(null, "", "cdie_pm_vc_config", cdie_pm_config))
            `uvm_fatal(get_type_name(), "Unable to get cdie_pm_vc_config from uvm_config_db");
    endfunction

    virtual task body();
        send_regio_txn_dmu_to_punit current_state_msg, current_state_valid_msg;
        current_state_msg = new();
        if(!current_state_msg.randomize() with {
                    register_addr == cdie_pm_config.diec_current_state_cdie2soc_addr;
                    register_data == {8'h0, 8'h0, 8'h0, current_state};
                })
            `uvm_fatal(get_type_name(), "Could not randomize current_state_msg object")
        current_state_msg.start(null);

        current_state_valid_msg = new();
        if(!current_state_valid_msg.randomize() with {
                    register_addr == cdie_pm_config.diec_status_update_valid_addr;
                    register_data == {8'h0, 8'h0, 8'h0, 8'h1}; //reg contains only one field, 'valid' at bit0
                })
            `uvm_fatal(get_type_name(), "Could not randomize current_state_valid_msg object")
        current_state_valid_msg.start(null);
    endtask

endclass

class cdie_send_nde extends uvm_sequence;

    `uvm_object_utils(cdie_send_nde)

    cdie_pm_vc_config cdie_pm_config;

    function new(string name="");
        super.new(name);
        if(!uvm_config_db#(cdie_pm_vc_config)::get(null, "", "cdie_pm_vc_config", cdie_pm_config))
            `uvm_fatal(get_type_name(), "Unable to get cdie_pm_vc_config from uvm_config_db");
    endfunction

    virtual task body();
        send_regio_txn_dmu_to_punit reg_write_seq = new();
        if(!reg_write_seq.randomize() with {
                    register_addr == cdie_pm_config.resource_nde_cdie2soc_addr;
                    register_data == {8'h0, 8'h0, 8'h0, 8'h0}; //value is don't care for now
                })
            `uvm_fatal(get_type_name(), "Could not randomize transaction object")
        reg_write_seq.start(null);
    endtask

endclass

class cdie_send_ltr extends uvm_sequence;

    `uvm_object_utils(cdie_send_ltr)

    cdie_pm_vc_config cdie_pm_config;

    function new(string name="");
        super.new(name);
        if(!uvm_config_db#(cdie_pm_vc_config)::get(null, "", "cdie_pm_vc_config", cdie_pm_config))
            `uvm_fatal(get_type_name(), "Unable to get cdie_pm_vc_config from uvm_config_db");
    endfunction

    virtual task body();
        send_regio_txn_dmu_to_punit reg_write_seq = new();
        if(!reg_write_seq.randomize() with {
                    register_addr == cdie_pm_config.resource_ltr_cdie2soc_addr;
                    register_data == {8'h0, 8'h0, 8'h0, 8'h0}; //value is don't care for now
                })
            `uvm_fatal(get_type_name(), "Could not randomize transaction object")
        reg_write_seq.start(null);
    endtask

endclass

class cdie_drive_signals extends uvm_sequence;

    `uvm_object_utils(cdie_drive_signals)

    rand bit pmsb_qreqn, gpsb_qreqn, idi_qreqn, pmsb_iso_req_b, gpsb_iso_req_b, idi_iso_req_b, idi_coherent_traffic_req;
    rand bit thermtripout, prochot_indication;
    static bit driving_signals = 0;

    virtual cdie_pm_vc_dielet_pm_if pmsb_dielet_vif, gpsb_dielet_vif, idi_dielet_vif;
    virtual cdie_pm_vc_if cdie_pm_vc_vif;

    constraint qreqn_c{
        soft pmsb_qreqn == pmsb_dielet_vif.QREQn;
        soft gpsb_qreqn == gpsb_dielet_vif.QREQn;
        soft idi_qreqn == idi_dielet_vif.QREQn;
        soft pmsb_iso_req_b == pmsb_dielet_vif.iso_req_b;
        soft gpsb_iso_req_b == gpsb_dielet_vif.iso_req_b;
        soft idi_iso_req_b == idi_dielet_vif.iso_req_b;
        soft idi_coherent_traffic_req == idi_dielet_vif.coherent_traffic_req;
        soft thermtripout == cdie_pm_vc_vif.thermtripout;
        soft prochot_indication == cdie_pm_vc_vif.prochot_indication;
    }

    function new(string name="");
        super.new(name);
        if(!uvm_config_db #(virtual cdie_pm_vc_dielet_pm_if)::get(null, "*", "cdie_pmsb_dielet_pm_if", pmsb_dielet_vif))
            `uvm_fatal(get_type_name(), "Unable to find the pmsb dielet virtual interface in the uvm_config_db")
        if(!uvm_config_db #(virtual cdie_pm_vc_dielet_pm_if)::get(null, "*", "cdie_gpsb_dielet_pm_if", gpsb_dielet_vif))
            `uvm_fatal(get_type_name(), "Unable to find the gpsb dielet virtual interface in the uvm_config_db")
        if(!uvm_config_db #(virtual cdie_pm_vc_dielet_pm_if)::get(null, "*", "cdie_idi_dielet_pm_if", idi_dielet_vif))
            `uvm_fatal(get_type_name(), "Unable to find the idi dielet virtual interface in the uvm_config_db")
        if(!uvm_config_db #(virtual cdie_pm_vc_if)::get(null, "*", "cdie_pm_vc_if", cdie_pm_vc_vif))
            `uvm_fatal(get_type_name(), "Unable to find the cdie virtual interface in the uvm_config_db")
    endfunction

    virtual task body();
        wait (driving_signals == 0);
        driving_signals = 1;
        fork
            cdie_pydoh_drive_sb_signals(pmsb_qreqn, gpsb_qreqn, idi_qreqn, pmsb_iso_req_b, gpsb_iso_req_b, idi_iso_req_b, idi_coherent_traffic_req, thermtripout, prochot_indication);
        join_none
        #1ns;
        driving_signals = 0;
    endtask

endclass
