class cdie_pm_vc_pkgc_test extends cdie_pm_vc_cold_boot_test;

    `uvm_component_utils(cdie_pm_vc_pkgc_test)

    cdie_send_wish_power_state send_wish_state;
    pkgc_send_power_state_req send_power_state_req;

    uvm_tlm_analysis_fifo #(iosfsbm_cm_uvm::xaction) sb_fifo;

    function new (string name="cdie_pm_vc_pkgc_test", uvm_component parent=null);
        super.new (name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        sb_fifo = new("sb_fifo", this);
    endfunction

    function void connect();
        super.connect();
        val_env.val_pmsb_agent.tx_ap.connect(this.sb_fifo.analysis_export);
    endfunction

    task delay_for_tb();
        #5ns;
    endtask

    virtual task test_content();
        super.test_content();
        delay_for_tb();
        drive_qreqs();
        send_wish_state = new("send_wish_state");
        send_wish_state.randomize() with {
            wish_state == DC1;
        };
        send_wish_state.start(null);
        `CALL_TASK_WITH_TIMEOUT(wait_for_wish_state(), 5)
        send_power_state_request(DC1, DC0);
        `CALL_TASK_WITH_TIMEOUT(wait_for_power_state_request(DC1, DC0, 'h1), 5)
        val_env.vc_env.power_state_response_handler_set_max_state(DC6);
        val_env.vc_env.power_state_response_handler_set_min_state(DC1);
        send_power_state_request(DC3_2, DC0);
        `CALL_TASK_WITH_TIMEOUT(wait_for_power_state_request(DC6, DC1, 'h1), 5)
        val_env.vc_env.power_state_response_handler_set_max_state(DC3_2);
        val_env.vc_env.power_state_response_handler_set_ack_state('b0);
        send_power_state_request(DC3_1, DC0);
        `CALL_TASK_WITH_TIMEOUT(wait_for_power_state_request(DC3_2, DC0, 'h0), 5)

        send_update_status(DC3_1);
        wait_for_update_status(DC3_1);
        wait_for_update_status_valid();

        test_send_power_info();
    endtask

    task drive_qreqs();
        cdie_drive_signals signals_seq;
        signals_seq = new("signals_seq");
        if(!signals_seq.randomize() with {pmsb_qreqn == 'b0; gpsb_qreqn == 'b0; idi_qreqn == 'b0;})
            `uvm_fatal(get_type_name(), "Could not randomize qreqn sequence")
        signals_seq.start(null);
        `CALL_TASK_WITH_TIMEOUT(wait(pmsb_dielet_vif.QREQn == 'b0), 1);
        `CALL_TASK_WITH_TIMEOUT(wait(gpsb_dielet_vif.QREQn == 'b0), 1);
        `CALL_TASK_WITH_TIMEOUT(wait(idi_dielet_vif.QREQn == 'b0), 1);

    endtask

    task send_power_state_request(cdie_cstate_t max_request_state, cdie_cstate_t min_request_state);
        send_power_state_req = new("send_power_state_req");
        send_power_state_req.randomize() with {
            max_state == max_request_state;
            min_state == min_request_state;
        };
        send_power_state_req.start(null);
    endtask

    task wait_for_wish_state();
        iosfsbm_cm_uvm::xaction txn;
        iosfsbm_cm_uvm::regio_xaction regio_txn;
        do sb_fifo.get(txn);
        while (!($cast(regio_txn, txn) && regio_txn.addr[0] == cdie_config.wish_power_state_cdie2soc_addr[7:0] && regio_txn.addr[1] == cdie_config.wish_power_state_cdie2soc_addr[15:8]));
    endtask

    task wait_for_power_state_request(cdie_cstate_t max, cdie_cstate_t min, logic[7:0] ack);
        iosfsbm_cm_uvm::xaction txn;
        iosfsbm_cm_uvm::regio_xaction regio_txn;
        do sb_fifo.get(txn);
        while (!($cast(regio_txn, txn) && regio_txn.addr[0] == cdie_config.power_state_rsp_cdie2soc_addr[7:0] && regio_txn.addr[1] == cdie_config.power_state_rsp_cdie2soc_addr[15:8]
                && regio_txn.data[0] == max && regio_txn.data[1] == min && regio_txn.data[2] == ack));
    endtask

    task send_update_status(cdie_cstate_t state);
        cdie_send_diec_current_state seq;
        seq = new();
        if(!seq.randomize() with {current_state == state;})
            `uvm_fatal(get_type_name(), "Could not randomize diec_send_current_state seq!")
        seq.start(null);
    endtask

    task wait_for_update_status(cdie_cstate_t state);
        iosfsbm_cm_uvm::xaction txn;
        iosfsbm_cm_uvm::regio_xaction regio_txn;
        do sb_fifo.get(txn);
        while (!($cast(regio_txn, txn) && regio_txn.addr[0] == cdie_config.diec_current_state_cdie2soc_addr[7:0] && regio_txn.addr[1] == cdie_config.diec_current_state_cdie2soc_addr[15:8]
                && regio_txn.data[0] == state));
    endtask

    task wait_for_update_status_valid();
        iosfsbm_cm_uvm::xaction txn;
        iosfsbm_cm_uvm::regio_xaction regio_txn;
        do sb_fifo.get(txn);
        while (!($cast(regio_txn, txn) && regio_txn.addr[0] == cdie_config.diec_status_update_valid_addr[7:0] && regio_txn.addr[1] == cdie_config.diec_status_update_valid_addr[15:8]
                && regio_txn.data[0] == 'h1));
    endtask

    task test_send_power_info();
        cdie_send_power_info_seq seq;
        seq = new();
        seq.start(null);

        `CALL_TASK_WITH_TIMEOUT(wait_for_power_info_message(), 5);
    endtask



endclass



module cdie_pm_vc_pkgc_test ();

    initial begin
        run_test("cdie_pm_vc_pkgc_test");
    end

endmodule
