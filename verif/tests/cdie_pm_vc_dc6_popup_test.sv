class cdie_pm_vc_dc6_popup_test extends cdie_pm_vc_dc_base_test;

    `uvm_component_utils(cdie_pm_vc_dc6_popup_test)

    function new (string name="cdie_pm_vc_dc6_popup_test", uvm_component parent=null);
        super.new (name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction

    function void connect();
        super.connect();
    endfunction

    virtual task test_content();
        do_cold_boot();
        delay_for_tb();

        request_dc_seq = new();
        request_dc_seq.randomize() with {
            state == DC6;
        };
        request_dc_seq.start(null);

        do_dc0_to_dc1();
        do_dc1_to_dc2_2('b1);
        do_dc2_2_to_dc6();

        delay_for_tb();

        `uvm_info(get_type_name(), "Popping up to DC2_2", UVM_LOW);
        pmsb_dielet_vif.QACTIVE = 'b1;
        do_dc6_to_dc2_2();

        pmsb_dielet_vif.QACTIVE = 'b0;
        deny_dc6_entry();
        allow_dc6_reentry();

        `uvm_info(get_type_name(), "Popping up to DC1 using IDI wake", UVM_LOW);
        idi_dielet_vif.QACTIVE = 'b1;

        fork
            do_dc6_to_dc2_2();
            begin
                #10ns;
                pmsb_dielet_vif.QACTIVE = 'b1;
            end
        join
        do_dc2_2_to_dc1('b1);
        
        #50ns;
        pmsb_dielet_vif.QACTIVE = 'b0;
        #100ns;
        idi_dielet_vif.QACTIVE = 'b0;

        do_dc1_to_dc2_2('b1);
        do_dc2_2_to_dc6();


        request_dc_seq = new();
        request_dc_seq.randomize() with {
            state == DC0;
        };
        request_dc_seq.start(null);

        #20ns;

        if(pmsb_dielet_vif.iso_req_b == 'b1)
            `uvm_error(get_type_name(), "DC6 exit began without a QACTIVE indication")

        pmsb_dielet_vif.QACTIVE = 'b1;
        do_dc6_to_dc2_2();
        do_dc2_2_to_dc1('b1);
        do_dc1_to_dc0();
    endtask

    task deny_dc6_entry();
        `CALL_TASK_WITH_TIMEOUT(wait_for_wish_state(DC6), 5);
        wait_for_svid_ownership_and_send_completion();
        send_power_state_request(DC6, DC6);

        `CALL_TASK_WITH_TIMEOUT(wait(gpsb_dielet_vif.QREQn == 0), 5);
        gpsb_dielet_vif.QACCEPTn = 0;

        `CALL_TASK_WITH_TIMEOUT(wait(pmsb_dielet_vif.QREQn == 0), 5);
        pmsb_dielet_vif.QDENY = 1;
        `CALL_TASK_WITH_TIMEOUT(wait(pmsb_dielet_vif.QREQn == 1), 5);
        pmsb_dielet_vif.QDENY = 0;

        `CALL_TASK_WITH_TIMEOUT(wait(pmsb_dielet_vif.QREQn == 0), 5);
        pmsb_dielet_vif.QDENY = 1;
        `CALL_TASK_WITH_TIMEOUT(wait(pmsb_dielet_vif.QREQn == 1), 5);
        pmsb_dielet_vif.QDENY = 0;

    endtask

    task allow_dc6_reentry();
        pmsb_dielet_vif.QACTIVE = 'b0;
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
    endtask
    
endclass


module cdie_pm_vc_dc6_popup_test ();

    initial begin
        run_test("cdie_pm_vc_dc6_popup_test");
    end

endmodule
