
// Request for DC3.1 entry
// Abort request by sending power state request shallower than current state
// Return to DC0


class cdie_pm_vc_dc3_abort_test extends cdie_pm_vc_dc_base_test;

    `uvm_component_utils(cdie_pm_vc_dc3_abort_test)

    function new (string name="cdie_pm_vc_dc3_test", uvm_component parent=null);
        super.new (name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction

    function void connect();
        super.connect();
    endfunction

    virtual task test_content();
        idi_dielet_vif.QACTIVE = 0;
        gpsb_dielet_vif.QACTIVE = 0;
        pmsb_dielet_vif.QACTIVE = 0;
        do_cold_boot();
        delay_for_tb();

        request_dc_seq = new();
        request_dc_seq.randomize() with {
            state == DC3_1;
        };
        request_dc_seq.start(null);

        do_dc0_to_dc1();
        do_dc1_to_dc2_1();
        do_dc2_1_to_dc3_1_with_abort();
        do_dc2_1_to_dc1_without_sending_power_state_req();
        do_dc1_to_dc0();
        
    endtask
    
    task do_dc2_1_to_dc3_1_with_abort();
        `CALL_TASK_WITH_TIMEOUT(wait_for_opmode_status(), 5);
        `CALL_TASK_WITH_TIMEOUT(wait_for_opmode_status_valid(), 5);

        `CALL_TASK_WITH_TIMEOUT(wait_for_wish_state(DC3_1), 5);
        
        send_power_state_request(DC0, DC0);
    endtask
    
    task do_dc2_1_to_dc1_without_sending_power_state_req();
        
         `CALL_TASK_WITH_TIMEOUT(wait_for_wish_state(DC1), 5);
        
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

endclass


module cdie_pm_vc_dc3_abort_test ();

    initial begin
        run_test("cdie_pm_vc_dc3_abort_test");
    end

endmodule
