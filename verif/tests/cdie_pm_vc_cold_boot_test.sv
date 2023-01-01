class cdie_pm_vc_cold_boot_test extends cdie_pm_vc_base_test;

    `uvm_component_utils(cdie_pm_vc_cold_boot_test)
    cdie_pm_start_boot_flow_seq boot_seq;
    soc2die_send_pm_sbb_ready send_sbb_ready_seq;
    soc2die_send_config_cycle_done send_cfg_cycle_done;
    soc2die_release_config_cycle_done release_cfg_cycle_done;
    soc2die_send_core_wake_ack core_wake_ack_seq;
    soc2die_send_bios_complete bios_complete_seq;
    svid_send_vr_alert send_vr_alert;
    svid_send_transmit_complete send_transmit_complete;
    svid_send_vr_settled send_vr_settled;
    pmsb_send_cmpd_msg_sequence svid_cmpd_seq;
    cdie_pm_vc_config cdie_config;
    virtual sideband_interface gpsb_agent_sideband_interface;
    virtual sideband_interface gpsb_fabric_sideband_interface;
    virtual sideband_interface pmsb_agent_sideband_interface;
    virtual sideband_interface pmsb_fabric_sideband_interface;
    virtual cdie_pm_vc_if pm_vif;
    virtual cdie_pm_vc_dielet_pm_if gpsb_dielet_vif, pmsb_dielet_vif, idi_dielet_vif;

    uvm_event cold_boot_config_cycle_ready;
    uvm_event svid_vr_req;
    uvm_event svid_vr_req_get_reg;
    uvm_event core_wake_req;

    int number_of_iterations = 1;
    uvm_tlm_analysis_fifo #(iosfsbm_cm_uvm::xaction) gpsb_fifo, pmsb_fifo;

    function new (string name="cdie_pm_vc_cold_boot_test", uvm_component parent=null);
        super.new (name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        gpsb_fifo = new("gpsb_fifo", this);
        pmsb_fifo = new("pmsb_fifo", this);
        if(!uvm_config_db #(virtual sideband_interface)::get(null, "*", "gpsb_agent_sideband_interface", gpsb_agent_sideband_interface))
            `uvm_fatal(get_type_name(), "Unable to find the gpsb_agent_sideband_interface virtual interface in the uvm_config_db")
        if(!uvm_config_db #(virtual sideband_interface)::get(null, "*", "gpsb_fabric_sideband_interface", gpsb_fabric_sideband_interface))
            `uvm_fatal(get_type_name(), "Unable to find the gpsb_fabric_sideband_interface virtual interface in the uvm_config_db")
        if(!uvm_config_db #(virtual sideband_interface)::get(null, "*", "pmsb_agent_sideband_interface", pmsb_agent_sideband_interface))
            `uvm_fatal(get_type_name(), "Unable to find the pmsb_agent_sideband_interface virtual interface in the uvm_config_db")
        if(!uvm_config_db #(virtual sideband_interface)::get(null, "*", "pmsb_fabric_sideband_interface", pmsb_fabric_sideband_interface))
            `uvm_fatal(get_type_name(), "Unable to find the pmsb_fabric_sideband_interface virtual interface in the uvm_config_db")
        if(!uvm_config_db #(virtual cdie_pm_vc_if)::get(null, "*", "cdie_pm_vc_if", pm_vif))
            `uvm_fatal(get_type_name(), "Unable to find the cdie_pm_vc_if virtual interface in the uvm_config_db")
        if(!uvm_config_db #(virtual cdie_pm_vc_dielet_pm_if)::get(null, "*", "cdie_pmsb_dielet_pm_if", pmsb_dielet_vif))
            `uvm_fatal(get_type_name(), "Unable to find the pmsb dielet virtual interface in the uvm_config_db")
        if(!uvm_config_db #(virtual cdie_pm_vc_dielet_pm_if)::get(null, "*", "cdie_gpsb_dielet_pm_if", gpsb_dielet_vif))
            `uvm_fatal(get_type_name(), "Unable to find the gpsb dielet virtual interface in the uvm_config_db")
        if(!uvm_config_db #(virtual cdie_pm_vc_dielet_pm_if)::get(null, "*", "cdie_idi_dielet_pm_if", idi_dielet_vif))
            `uvm_fatal(get_type_name(), "Unable to find the idi dielet virtual interface in the uvm_config_db")
    endfunction

    function void connect();
        super.connect();
        if(!uvm_config_db#(cdie_pm_vc_config)::get(null, "*", "cdie_pm_vc_config", cdie_config))
            `uvm_fatal(get_type_name(), "Unable to find the cdie_pm_vc_config in the uvm_config_db")
        val_env.val_gpsb_agent.tx_ap.connect(this.gpsb_fifo.analysis_export);
        val_env.val_pmsb_agent.tx_ap.connect(this.pmsb_fifo.analysis_export);
        if ($test$plusargs("send_svid_alert_ready"))
            cdie_config.send_svid_alert_ready = 1;
    endfunction

    task delay_for_tb();
        #5ns;
    endtask

    virtual task test_content();
        do_cold_boot();
    endtask

    task do_cold_boot();
        initialize_signals();
        boot_seq = new();
        boot_seq.start(null);
        create_watchers();
        delay_for_tb();
        bring_sideband_out_of_reset();
        assert_early_boot_pd_on();
        delay_for_tb();
        assert_cold_boot_trigger();
        assert_warm_boot_trigger();
        `CALL_TASK_WITH_TIMEOUT(wait_for_iso_req_b(), 1);
        deassert_iso_ack_b();
        fork_off_wait_for_tscdownloadtrigger();
        delay_for_tb();
        `CALL_TASK_WITH_TIMEOUT(do_qreq_handshake(), 10);
        send_sbb_ready();
        `CALL_TASK_WITH_TIMEOUT(cold_boot_config_cycle_ready.wait_trigger(), 10);
        send_config_cycle_done();
        release_config_cycle_done();
        do_svid_handshakes();
        `CALL_TASK_WITH_TIMEOUT(core_wake_req.wait_trigger(), 1)
        send_core_wake_ack();
        send_bios_complete();
        `CALL_TASK_WITH_TIMEOUT(wait_for_power_info_message(), 2);
        `CALL_TASK_WITH_TIMEOUT(wait(idi_dielet_vif.coherent_traffic_req == 1), 1)
        send_mailbox_request();
        `CALL_TASK_WITH_TIMEOUT(wait_for_mailbox_response(), 2)
    endtask

    task initialize_signals();
        pm_vif.warm_boot_trigger = 0;
        pm_vif.cold_boot_trigger = 0;
        pm_vif.early_boot_pd_on = 0;
        pm_vif.bclk_clk_ack = 1;
        pm_vif.xtal_clk_ack = 1;
        pm_vif.cro_clk_ack = 1;

        idi_dielet_vif.iso_ack_b = 0;
        idi_dielet_vif.QACCEPTn = 0;
        idi_dielet_vif.QDENY = 0;
        idi_dielet_vif.QACTIVE = 0;

        gpsb_dielet_vif.iso_ack_b = 0;
        gpsb_dielet_vif.QACCEPTn = 0;
        gpsb_dielet_vif.QDENY = 0;
        gpsb_dielet_vif.QACTIVE = 0;

        pmsb_dielet_vif.iso_ack_b = 0;
        pmsb_dielet_vif.QACCEPTn = 0;
        pmsb_dielet_vif.QDENY = 0;
        pmsb_dielet_vif.QACTIVE = 0;
    endtask

    function void create_watchers();
        cold_boot_config_cycle_ready = uvm_event_pool::get_global("cold_boot_config_cycle_ready");
        svid_vr_req = uvm_event_pool::get_global("svid_vr_req");
        svid_vr_req_get_reg = uvm_event_pool::get_global("svid_vr_req_get_reg");
        core_wake_req = uvm_event_pool::get_global("core_wake_req");
    endfunction

    task bring_sideband_out_of_reset();
        gpsb_agent_sideband_interface.side_rst_b = 1'b1;
        pmsb_agent_sideband_interface.side_rst_b = 1'b1;
        #1ns;
        gpsb_fabric_sideband_interface.side_rst_b = 1'b1;
        pmsb_fabric_sideband_interface.side_rst_b = 1'b1;
    endtask

    function void assert_early_boot_pd_on();
        pm_vif.early_boot_pd_on = 1;
    endfunction

    function void assert_cold_boot_trigger();
        pm_vif.cold_boot_trigger = 1;
    endfunction

    function void assert_warm_boot_trigger();
        pm_vif.warm_boot_trigger = 1;
    endfunction

    function void deassert_iso_ack_b();
        gpsb_dielet_vif.iso_ack_b = 1'b1;
        pmsb_dielet_vif.iso_ack_b = 1'b1;
        idi_dielet_vif.iso_ack_b = 1'b1;
    endfunction

    task wait_for_iso_req_b();
        wait(gpsb_dielet_vif.iso_req_b == 1'b1);
        wait(pmsb_dielet_vif.iso_req_b == 1'b1);
        wait(idi_dielet_vif.iso_req_b == 1'b1);
    endtask

    task fork_off_wait_for_tscdownloadtrigger();
        fork
            begin
                wait(pm_vif.TSCDownLoadTrigger) begin
                    $display("Got TSCDownLoadTrigger: Non-Blocking per HAS");
                end
            end
        join_none
    endtask

    task do_qreq_handshake();
        #(cdie_config.gpsb_qreqn_delay_in_ps * 1ps);
        fork
            begin
                wait(gpsb_dielet_vif.QREQn === 1'b1)
                gpsb_dielet_vif.QACCEPTn = 1'b1;
            end
            begin
                wait(pmsb_dielet_vif.QREQn === 1'b1)
                pmsb_dielet_vif.QACCEPTn = 1'b1;
            end
            begin
                wait(idi_dielet_vif.QREQn === 1'b1)
                idi_dielet_vif.QACCEPTn = 1'b1;
            end
        join
    endtask

    task send_sbb_ready();
        send_sbb_ready_seq = new("sbb_ready_seq");
        send_sbb_ready_seq.start(null);
    endtask

    task send_config_cycle_done();
        send_cfg_cycle_done = new("config_cycle_done");
        send_cfg_cycle_done.start(null);
    endtask

    task release_config_cycle_done();
        release_cfg_cycle_done = new("release_cfg_cycle_done");
        release_cfg_cycle_done.start(null);
    endtask

    task do_svid_handshakes();       
        if(cdie_config.send_svid_alert_ready == 1)
            `CALL_TASK_WITH_TIMEOUT(wait_for_svid_alert_ready(), 5)

            `CALL_TASK_WITH_TIMEOUT(svid_vr_req.wait_trigger(), 1)
            send_svid_vr_response_transmit_done();
        delay_for_tb();
        send_svid_vr_alert();
        `CALL_TASK_WITH_TIMEOUT(svid_vr_req_get_reg.wait_trigger(), 1)
        send_svid_vr_settled();
    endtask

    task send_svid_vr_response_transmit_done();
        send_transmit_complete = new("send_transmit_complete");
        send_transmit_complete.start(null);
    endtask

    task send_svid_vr_alert();
        send_vr_alert = new("send_svid_vr_alert");
        send_vr_alert.start(null);
    endtask

    task send_svid_vr_settled();
        send_vr_settled = new("send_vr_settled");
        send_vr_settled.start(null);
    endtask

    task send_core_wake_ack();
        core_wake_ack_seq = new("send_core_wake_ack");
        core_wake_ack_seq.start(null);

    endtask

    task send_bios_complete();
        soc2die_send_bios_complete bios_complete_seq;
        bios_complete_seq = new("bios_complete_seq");
        bios_complete_seq.start(null);
    endtask

    task send_mailbox_request();
        mailbox_cr_write_seq seq;
        seq = new("mailbox_cr_write_seq");
        seq.start(null);
    endtask

    task wait_for_mailbox_response();
        iosfsbm_cm_uvm::xaction txn;
        iosfsbm_cm_uvm::regio_xaction regio_txn;
        do gpsb_fifo.get(txn);
        while (!($cast(regio_txn, txn) && regio_txn.addr[0] == cdie_config.pcode2dcode_mailbox_local_addr[7:0] && regio_txn.addr[1] == cdie_config.pcode2dcode_mailbox_local_addr[15:8]) && regio_txn.data[0][31] == 'b0);
    endtask

    task wait_for_power_info_message();
        iosfsbm_cm_uvm::xaction txn;
        iosfsbm_cm_uvm::regio_xaction regio_txn;
        do gpsb_fifo.get(txn);
        while (!($cast(regio_txn, txn) && regio_txn.addr[0] == cdie_config.dmu_event_3_addr[7:0] && regio_txn.addr[1] == cdie_config.dmu_event_3_addr[15:8]
                && regio_txn.data[0] == 'h5 && regio_txn.data[1] == 'h0 && regio_txn.data[2] == 'h5 && regio_txn.data[3] == 'h0));
    endtask

    task wait_for_svid_alert_ready();
        iosfsbm_cm_uvm::xaction txn;
        iosfsbm_cm_uvm::regio_xaction regio_txn;
        do pmsb_fifo.get(txn);
        while (!($cast(regio_txn, txn) && regio_txn.addr[0] == cdie_config.die2soc_reset_flow_control_addr[7:0] && regio_txn.addr[1] == cdie_config.die2soc_reset_flow_control_addr[15:8]
                && regio_txn.data[0][2] == 1));
    endtask

endclass



module cdie_pm_vc_cold_boot_test ();

    initial begin
        run_test("cdie_pm_vc_cold_boot_test");
    end

endmodule
