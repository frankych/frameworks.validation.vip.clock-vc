class cdie_pm_vc_dc_base_test extends cdie_pm_vc_cold_boot_test;

    `uvm_component_utils(cdie_pm_vc_dc_base_test)
    
    cdie_set_target_power_state request_dc_seq;
    cdie_send_wish_power_state send_wish_state;
    pkgc_send_power_state_req send_power_state_req;
    pmsb_send_cmp_msg_sequence send_completion_seq;
    
    uvm_tlm_analysis_fifo #(iosfsbm_cm_uvm::xaction) pmsb_diec_state_fifo;
    
    function new (string name="cdie_pm_vc_dc_base_test", uvm_component parent=null);
        super.new (name, parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        pmsb_diec_state_fifo = new("pmsb_diec_state_fifo", this);
    endfunction

    function void connect();
        super.connect();
        val_env.val_pmsb_agent.tx_ap.connect(this.pmsb_diec_state_fifo.analysis_export);
    endfunction
    
    task delay_for_tb();
        #5ns;
    endtask
    
    task wait_for_wish_state(cdie_cstate_t state);
        iosfsbm_cm_uvm::xaction txn;
        iosfsbm_cm_uvm::regio_xaction regio_txn;
        do begin
            pmsb_fifo.get(txn);
            $display("mooga got a txn, trying to cast");
            if( $cast(regio_txn, txn)) begin
                $display("mooga cast txn");
                $display("mooga addr[0] is %h, addr[1] is %h, data is %h", regio_txn.addr[0], regio_txn.addr[1], regio_txn.data[0]);
            end
        end
        while (!($cast(regio_txn, txn) && regio_txn.addr[0] == cdie_config.wish_power_state_cdie2soc_addr[7:0] && regio_txn.addr[1] == cdie_config.wish_power_state_cdie2soc_addr[15:8] && regio_txn.data[0] == state));
    endtask
    
    task send_power_state_request(cdie_cstate_t max_request_state, cdie_cstate_t min_request_state);
        send_power_state_req = new("send_power_state_req");
        send_power_state_req.randomize() with {
            max_state == max_request_state;
            min_state == min_request_state;
        };
        send_power_state_req.start(null);
    endtask
    
    task wait_for_svid_ownership_and_send_completion();
        iosfsbm_cm_uvm::xaction txn;
        iosfsbm_cm_uvm::regio_xaction regio_txn;
        do pmsb_fifo.get(txn);
        while (!($cast(regio_txn, txn) && regio_txn.addr[0] == cdie_config.svid_ownership_semaphore_addr[7:0] && regio_txn.addr[1] == cdie_config.svid_ownership_semaphore_addr[15:8] && regio_txn.data[0] == 'b1));
    endtask
    
    task wait_for_opmode_status();
        iosfsbm_cm_uvm::xaction txn;
        iosfsbm_cm_uvm::regio_xaction regio_txn;
        do pmsb_fifo.get(txn);
        while (!($cast(regio_txn, txn) && regio_txn.addr[0] == cdie_config.resource_operating_mode_status_cdie2soc_addr[7:0] && regio_txn.addr[1] == cdie_config.resource_operating_mode_status_cdie2soc_addr[15:8]));
    endtask

    task wait_for_opmode_status_valid();
        iosfsbm_cm_uvm::xaction txn;
        iosfsbm_cm_uvm::regio_xaction regio_txn;
        do pmsb_fifo.get(txn);
        while (!($cast(regio_txn, txn) && regio_txn.addr[0] == cdie_config.resource_operating_mode_status_valid_cdie2soc_addr[7:0] && regio_txn.addr[1] == cdie_config.resource_operating_mode_status_valid_cdie2soc_addr[15:8]));
    endtask
    
    task wait_for_update_status(cdie_cstate_t state);
        iosfsbm_cm_uvm::xaction txn;
        iosfsbm_cm_uvm::regio_xaction regio_txn;
        pmsb_diec_state_fifo.flush();
        do pmsb_diec_state_fifo.get(txn);
        while (!($cast(regio_txn, txn) && regio_txn.addr[0] == cdie_config.diec_current_state_cdie2soc_addr[7:0] && regio_txn.addr[1] == cdie_config.diec_current_state_cdie2soc_addr[15:8]
                && regio_txn.data[0] == state));
    endtask

    task wait_for_update_status_valid();
        iosfsbm_cm_uvm::xaction txn;
        iosfsbm_cm_uvm::regio_xaction regio_txn;
        do pmsb_diec_state_fifo.get(txn);
        while (!($cast(regio_txn, txn) && regio_txn.addr[0] == cdie_config.diec_status_update_valid_addr[7:0] && regio_txn.addr[1] == cdie_config.diec_status_update_valid_addr[15:8]
                && regio_txn.data[0] == 'h1));
    endtask
    
    task do_dc0_to_dc1();
        `CALL_TASK_WITH_TIMEOUT(wait_for_wish_state(DC1), 5)

        send_power_state_request(DC1, DC0);
        `CALL_TASK_WITH_TIMEOUT(wait_for_opmode_status(), 5)
        `CALL_TASK_WITH_TIMEOUT(wait_for_opmode_status_valid(), 5)
        `CALL_TASK_WITH_TIMEOUT(wait(pm_vif.cdie_current_state == DC1), 5)
    endtask

    task do_dc1_to_dc0();

        `CALL_TASK_WITH_TIMEOUT(wait_for_wish_state(DC0), 5)

        send_power_state_request(DC0, DC0);
        `CALL_TASK_WITH_TIMEOUT(wait_for_update_status(DC0), 5)
        `CALL_TASK_WITH_TIMEOUT(wait_for_update_status_valid(), 5)
        `CALL_TASK_WITH_TIMEOUT(wait(pm_vif.cdie_current_state == DC0), 5)
    endtask
    
    task do_dc1_to_dc2_1();

        `CALL_TASK_WITH_TIMEOUT(wait_for_wish_state(DC2_1), 5);
        send_power_state_request(DC2_1, DC0);

        `CALL_TASK_WITH_TIMEOUT(wait(idi_dielet_vif.QREQn == 0), 5);
        idi_dielet_vif.QACCEPTn = 0;

        `CALL_TASK_WITH_TIMEOUT(wait(idi_dielet_vif.iso_req_b == 0), 5);
        idi_dielet_vif.iso_ack_b = 0;

        if (idi_dielet_vif.coherent_traffic_req == 'b0)
            `uvm_error(get_type_name(), "Saw coherent traffic req drop in dc2_1 entry flow")

        `CALL_TASK_WITH_TIMEOUT(wait(pm_vif.cdie_current_state == DC2_1), 5)
    endtask
    
    task do_dc2_1_to_dc1();
        
         `CALL_TASK_WITH_TIMEOUT(wait_for_wish_state(DC1), 5);
        send_power_state_request(DC1, DC0);
        
        `CALL_TASK_WITH_TIMEOUT(wait(idi_dielet_vif.iso_req_b == 1), 5);
        idi_dielet_vif.iso_ack_b = 1;

        `CALL_TASK_WITH_TIMEOUT(wait(idi_dielet_vif.QREQn == 1), 5);
        idi_dielet_vif.QACCEPTn = 1;

        `CALL_TASK_WITH_TIMEOUT(wait_for_opmode_status(), 5);
        `CALL_TASK_WITH_TIMEOUT(wait_for_opmode_status_valid(), 5);

        `CALL_TASK_WITH_TIMEOUT(wait_for_update_status(DC1), 5)
        `CALL_TASK_WITH_TIMEOUT(wait_for_update_status_valid(), 5)

        `CALL_TASK_WITH_TIMEOUT(wait(pm_vif.cdie_current_state == DC1), 5)
    endtask
    
    task do_dc1_to_dc2_2(bit send_power_state_req);

        `CALL_TASK_WITH_TIMEOUT(wait(idi_dielet_vif.coherent_traffic_req == 0), 5)
        `CALL_TASK_WITH_TIMEOUT(wait_for_opmode_status(), 5);
        `CALL_TASK_WITH_TIMEOUT(wait_for_opmode_status_valid(), 5);

        `CALL_TASK_WITH_TIMEOUT(wait_for_wish_state(DC2_2), 5);
        if (send_power_state_req == 'b1)
            send_power_state_request(DC2_2, DC0);

        `CALL_TASK_WITH_TIMEOUT(wait(idi_dielet_vif.QREQn == 0), 5);
        idi_dielet_vif.QACCEPTn = 0;

        `CALL_TASK_WITH_TIMEOUT(wait(idi_dielet_vif.iso_req_b == 0), 5);
        idi_dielet_vif.iso_ack_b = 0;
        `CALL_TASK_WITH_TIMEOUT(wait(pm_vif.cdie_current_state == DC2_2), 5)

    endtask
    
    task do_dc2_2_to_dc1(bit send_power_state_req);

        `CALL_TASK_WITH_TIMEOUT(wait_for_wish_state(DC1), 5);
        if (send_power_state_req == 1)
            send_power_state_request(DC1, DC1);

        `CALL_TASK_WITH_TIMEOUT(wait(idi_dielet_vif.iso_req_b == 1), 5);
        idi_dielet_vif.iso_ack_b = 1;

        `CALL_TASK_WITH_TIMEOUT(wait(idi_dielet_vif.QREQn == 1), 5);
        idi_dielet_vif.QACCEPTn = 1;

        `CALL_TASK_WITH_TIMEOUT(wait_for_opmode_status(), 5);
        `CALL_TASK_WITH_TIMEOUT(wait_for_opmode_status_valid(), 5);
        `CALL_TASK_WITH_TIMEOUT(wait(pm_vif.cdie_current_state == DC1), 5)

    endtask
    
    task do_dc2_1_to_dc3_1();
        `CALL_TASK_WITH_TIMEOUT(wait_for_opmode_status(), 5);
        `CALL_TASK_WITH_TIMEOUT(wait_for_opmode_status_valid(), 5);

        `CALL_TASK_WITH_TIMEOUT(wait_for_wish_state(DC3_1), 5);

        send_power_state_request(DC3_1, DC0);
        wait_for_svid_ownership_and_send_completion();

        `CALL_TASK_WITH_TIMEOUT(wait(gpsb_dielet_vif.QREQn == 0), 5);
        gpsb_dielet_vif.QACCEPTn = 0;

        `CALL_TASK_WITH_TIMEOUT(wait(pmsb_dielet_vif.QREQn == 0), 5);
        pmsb_dielet_vif.QACCEPTn = 0;

        if (cdie_config.toggle_clocks_during_dcstate) begin
            `CALL_TASK_WITH_TIMEOUT(wait(pm_vif.bclk_clk_req == 0), 5)
            pm_vif.bclk_clk_ack = 0;
        end

        `CALL_TASK_WITH_TIMEOUT(wait(pm_vif.cdie_current_state == DC3_1), 5)
    endtask

    task do_dc3_1_to_dc2_1();

        if (cdie_config.toggle_clocks_during_dcstate) begin
            `CALL_TASK_WITH_TIMEOUT(wait(pm_vif.bclk_clk_req == 1), 5)
            pm_vif.bclk_clk_ack = 1;
        end

        `CALL_TASK_WITH_TIMEOUT(wait(pmsb_dielet_vif.QREQn == 1), 5);
        pmsb_dielet_vif.QACCEPTn = 1;

        `CALL_TASK_WITH_TIMEOUT(wait(gpsb_dielet_vif.QREQn == 1), 5);
        gpsb_dielet_vif.QACCEPTn = 1;

        `CALL_TASK_WITH_TIMEOUT(wait_for_wish_state(DC2_1), 5);

        send_power_state_request(DC2_1, DC0);

        `CALL_TASK_WITH_TIMEOUT(wait_for_opmode_status(), 5);
        `CALL_TASK_WITH_TIMEOUT(wait_for_opmode_status_valid(), 5);

        `CALL_TASK_WITH_TIMEOUT(wait_for_update_status(DC2_1), 5)
        `CALL_TASK_WITH_TIMEOUT(wait_for_update_status_valid(), 5)

        `CALL_TASK_WITH_TIMEOUT(wait(pm_vif.cdie_current_state == DC2_1), 5)
    endtask
    
    task do_dc2_2_to_dc3_2(bit send_power_state_req);
        `CALL_TASK_WITH_TIMEOUT(wait_for_opmode_status(), 5);
        `CALL_TASK_WITH_TIMEOUT(wait_for_opmode_status_valid(), 5);

        `CALL_TASK_WITH_TIMEOUT(wait_for_wish_state(DC3_2), 5);
        if (send_power_state_req == 'b1)
            send_power_state_request(DC3_2, DC0);
        wait_for_svid_ownership_and_send_completion();

        `CALL_TASK_WITH_TIMEOUT(wait(gpsb_dielet_vif.QREQn == 0), 5);
        gpsb_dielet_vif.QACCEPTn = 0;

        `CALL_TASK_WITH_TIMEOUT(wait(pmsb_dielet_vif.QREQn == 0), 5);
        pmsb_dielet_vif.QACCEPTn = 0;

        if (cdie_config.toggle_clocks_during_dcstate) begin
            `CALL_TASK_WITH_TIMEOUT(wait(pm_vif.bclk_clk_req == 0), 5)
            pm_vif.bclk_clk_ack = 0;
        end

        `CALL_TASK_WITH_TIMEOUT(wait(pm_vif.cdie_current_state == DC3_2), 5)
    endtask

    task do_dc3_2_to_dc2_2(bit send_power_state_req);
        if (cdie_config.toggle_clocks_during_dcstate) begin
            `CALL_TASK_WITH_TIMEOUT(wait(pm_vif.bclk_clk_req == 1), 5)
            pm_vif.bclk_clk_ack = 1;
        end

        `CALL_TASK_WITH_TIMEOUT(wait(pmsb_dielet_vif.QREQn == 1), 5);
        pmsb_dielet_vif.QACCEPTn = 1;

        `CALL_TASK_WITH_TIMEOUT(wait(gpsb_dielet_vif.QREQn == 1), 5);
        gpsb_dielet_vif.QACCEPTn = 1;

        `CALL_TASK_WITH_TIMEOUT(wait_for_wish_state(DC2_2), 5);

        if(send_power_state_req == 'b1)
            send_power_state_request(DC2_2, DC0);

        `CALL_TASK_WITH_TIMEOUT(wait_for_opmode_status(), 5);
        `CALL_TASK_WITH_TIMEOUT(wait_for_opmode_status_valid(), 5);

        `CALL_TASK_WITH_TIMEOUT(wait_for_update_status(DC2_2), 5)
        `CALL_TASK_WITH_TIMEOUT(wait_for_update_status_valid(), 5)

        `CALL_TASK_WITH_TIMEOUT(wait(pm_vif.cdie_current_state == DC2_2), 5)
    endtask
    
    task do_dc2_2_to_dc6();
        `CALL_TASK_WITH_TIMEOUT(wait_for_wish_state(DC6), 5);
        send_power_state_request(DC6, DC6);
        wait_for_svid_ownership_and_send_completion();

        `CALL_TASK_WITH_TIMEOUT(wait(gpsb_dielet_vif.QREQn == 0), 5);
        gpsb_dielet_vif.QACCEPTn = 0;

        `CALL_TASK_WITH_TIMEOUT(wait(pmsb_dielet_vif.QREQn == 0), 5);
        pmsb_dielet_vif.QACCEPTn = 0;

        `CALL_TASK_WITH_TIMEOUT(wait(gpsb_dielet_vif.iso_req_b == 0), 5);
        gpsb_dielet_vif.iso_ack_b = 0;

        `CALL_TASK_WITH_TIMEOUT(wait(pmsb_dielet_vif.iso_req_b == 0), 5);
        pmsb_dielet_vif.iso_ack_b = 0;

        `CALL_TASK_WITH_TIMEOUT(wait(pm_vif.local_half_bridge_rst_b_sync == 0), 5);

        if (cdie_config.toggle_clocks_during_dcstate) begin
            `CALL_TASK_WITH_TIMEOUT(wait(pm_vif.bclk_clk_req == 0), 5)
            pm_vif.bclk_clk_ack = 0;

            `CALL_TASK_WITH_TIMEOUT(wait(pm_vif.xtal_clk_req == 0), 5)
            pm_vif.xtal_clk_ack = 0;

            `CALL_TASK_WITH_TIMEOUT(wait(pm_vif.cro_clk_req == 0), 5)
            pm_vif.cro_clk_ack = 0;
        end

        `CALL_TASK_WITH_TIMEOUT(wait(pm_vif.cdie_current_state == DC6), 5)

    endtask

    task do_dc6_to_dc2_2();

        if (cdie_config.toggle_clocks_during_dcstate) begin
            `CALL_TASK_WITH_TIMEOUT(wait(pm_vif.cro_clk_req == 1), 5)
            pm_vif.cro_clk_ack = 1;

            `CALL_TASK_WITH_TIMEOUT(wait(pm_vif.xtal_clk_req == 1), 5)
            pm_vif.xtal_clk_ack = 1;

            `CALL_TASK_WITH_TIMEOUT(wait(pm_vif.bclk_clk_req == 1), 5)
            pm_vif.bclk_clk_ack = 1;

        end

        `CALL_TASK_WITH_TIMEOUT(wait(pmsb_dielet_vif.iso_req_b == 1), 5);
        pmsb_dielet_vif.iso_ack_b = 1;

        `CALL_TASK_WITH_TIMEOUT(wait(gpsb_dielet_vif.iso_req_b == 1), 5);
        gpsb_dielet_vif.iso_ack_b = 1;

        `CALL_TASK_WITH_TIMEOUT(wait(pm_vif.local_half_bridge_rst_b_sync == 1), 5);

        `CALL_TASK_WITH_TIMEOUT(wait(pmsb_dielet_vif.QREQn == 1), 5);
        pmsb_dielet_vif.QACCEPTn = 1;

        `CALL_TASK_WITH_TIMEOUT(wait(gpsb_dielet_vif.QREQn == 1), 5);
        gpsb_dielet_vif.QACCEPTn = 1;

        `CALL_TASK_WITH_TIMEOUT(wait_for_wish_state(DC2_2), 5);
        send_power_state_request(DC6, DC2_2);

        `CALL_TASK_WITH_TIMEOUT(wait_for_opmode_status(), 5);
        `CALL_TASK_WITH_TIMEOUT(wait_for_opmode_status_valid(), 5);
        `CALL_TASK_WITH_TIMEOUT(wait(pm_vif.cdie_current_state == DC2_2), 5)
    endtask
    
endclass
    