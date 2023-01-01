class cdie_sb_base_watcher extends uvm_component;
    `uvm_component_utils(cdie_sb_base_watcher)

    uvm_tlm_analysis_fifo #(iosfsbm_cm_uvm::xaction) sideband_input_fifo;
    cdie_clk_vc_config cdie_clk_vc_cfg;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        sideband_input_fifo = new("sideband_input_fifo", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if(!uvm_config_db #(cdie_clk_vc_config)::get(null, "", "cdie_clk_vc_config", cdie_clk_vc_cfg))
            `uvm_fatal(get_type_name(), "Could not get cdie_vc_gen_config from uvm config db")
    endfunction

    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);
        start_watching_sb();
    endtask

    virtual task start_watching_sb();
        iosfsbm_cm_uvm::xaction txn;
        forever begin
            sideband_input_fifo.get(txn);
            check_for_wanted_sb_sideband_traffic(txn);
        end
    endtask

    task check_for_wanted_sb_sideband_traffic(iosfsbm_cm_uvm::xaction txn);
        iosfsbm_cm_uvm::regio_xaction regio_txn;
        if (txn.xaction_type == iosfsbm_cm_uvm::REGIO) begin
            if (!$cast(regio_txn, txn))
                `uvm_fatal(get_type_name(), "Casting sideband txn to regio_txn failed.  Please check that the types are correct");
            check_regio_wanted(regio_txn);
        end
    endtask

    virtual task check_regio_wanted(iosfsbm_cm_uvm::regio_xaction regio_txn);
    endtask

endclass


class cdie_gpsb_watcher extends cdie_sb_base_watcher;

    `uvm_component_utils(cdie_gpsb_watcher)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
    endtask

    task check_regio_wanted(iosfsbm_cm_uvm::regio_xaction regio_txn);
    endtask

endclass

class cdie_pmsb_watcher extends cdie_sb_base_watcher;

    `uvm_component_utils(cdie_pmsb_watcher)

    uvm_event cold_boot_config_cycle_ready;
    uvm_event core_wake_req;
    uvm_event svid_vr_req;
    uvm_event svid_vr_req_get_reg;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
    endfunction

    task run_phase(uvm_phase phase);
        cold_boot_config_cycle_ready = uvm_event_pool::get_global("cold_boot_config_cycle_ready");
        core_wake_req = uvm_event_pool::get_global("core_wake_req");
        svid_vr_req = uvm_event_pool::get_global("svid_vr_req");
        svid_vr_req_get_reg = uvm_event_pool::get_global("svid_vr_req_get_reg");
        super.run_phase(phase);
    endtask

    task check_regio_wanted(iosfsbm_cm_uvm::regio_xaction regio_txn);
        check_die2soc_reset_flow_control(regio_txn);
        check_svid_transactions(regio_txn);
    endtask

    function void check_die2soc_reset_flow_control(iosfsbm_cm_uvm::regio_xaction regio_txn);
        logic [7:0] die2soc_reset_flow_control_address [2] = '{cdie_clk_vc_cfg.die2soc_reset_flow_control_addr[7:0], cdie_clk_vc_cfg.die2soc_reset_flow_control_addr[15:8]};
        if (regio_txn.addr[0:1] == die2soc_reset_flow_control_address[0:1] && ((regio_txn.src_pid == cdie_clk_vc_cfg.dmu_pmsb_portid[15:8] && regio_txn.local_src_pid == cdie_clk_vc_cfg.dmu_pmsb_portid[7:0] && regio_txn.global_intf_en) || (regio_txn.src_pid == cdie_clk_vc_cfg.dmu_pmsb_portid[7:0] && regio_txn.global_intf_en == 0))) begin
            check_core_wake_req(regio_txn.data[0][1]);
            check_cold_boot_config_cycle_ready(regio_txn.data[0][0]);
        end
    endfunction

    function void check_svid_transactions(iosfsbm_cm_uvm::regio_xaction regio_txn);
        logic [7:0] reg_data [4];
        logic [7:0] vr_req_addr[2];
        logic [7:0] vr_alert_addr[2];

        vr_req_addr = '{cdie_clk_vc_cfg.svid_vr_req_cdie_addr[7:0], cdie_clk_vc_cfg.svid_vr_req_cdie_addr[15:8]};
        $display("actual addr is %h_%h, exepcted addr is %h_%h", regio_txn.addr[0], regio_txn.addr[1], vr_req_addr[0], vr_req_addr[1]);
        if (regio_txn.addr[0:1] == vr_req_addr) begin
            logic [4:0] command;
            logic [3:0] vr_address;
            logic enable_alert;
            $display("Saw vr_req");
            $display("data is %h_%h_%h_%h", regio_txn.data[3], regio_txn.data[2], regio_txn.data[1], regio_txn.data[0]);
            command = regio_txn.data[1][4:0];
            vr_address = regio_txn.data[2][3:0];
            enable_alert = regio_txn.data[3][7];
            $display("Command: %h, Vr Address: %h, Enable Alert: %h", command, vr_address, enable_alert);
            if (enable_alert == 1'b1 && vr_address == cdie_clk_vc_cfg.svid_address) begin
                if (command == SET_VID_FAST || command == SET_VID_SLOW || command == SET_VID_DECAY)
                    svid_vr_req.trigger();
                if (command == GET_REG)
                    svid_vr_req_get_reg.trigger();
            end
        end

    endfunction

    function void trigger_if_set(bit data_to_check, uvm_event event_to_trigger);
        if (data_to_check == 1'b1) begin
            event_to_trigger.trigger();
        end
    endfunction

    function void check_cold_boot_config_cycle_ready(bit data_to_check);
        trigger_if_set(data_to_check, cold_boot_config_cycle_ready);
    endfunction

    function void check_core_wake_req(bit data_to_check);
        trigger_if_set(data_to_check, core_wake_req);
    endfunction

endclass
