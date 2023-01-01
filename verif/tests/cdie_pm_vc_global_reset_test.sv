class cdie_pm_vc_global_reset_test extends cdie_pm_vc_cold_boot_test;

    `uvm_component_utils(cdie_pm_vc_global_reset_test)



    function new (string name="cdie_pm_vc_global_reset_test", uvm_component parent=null);
        super.new (name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

    endfunction

    function void connect();
        super.connect();
    endfunction

    task delay_for_tb();
        #5ns;
    endtask

    virtual task test_content();
        super.test_content();
        delay_for_tb();
        pm_vif.warm_boot_trigger = 0;
        do_qreq_handshake(gpsb_dielet_vif);
        do_qreq_handshake(idi_dielet_vif);
        do_qreq_handshake(pmsb_dielet_vif);
        `CALL_TASK_WITH_TIMEOUT(wait(idi_dielet_vif.coherent_traffic_req == 0), 5);
        pm_vif.cold_boot_trigger = 'b0;
        do_iso_handshake(gpsb_dielet_vif);
        do_iso_handshake(idi_dielet_vif);
        do_iso_handshake(pmsb_dielet_vif);
        pm_vif.early_boot_pd_on = 'b0;
        delay_for_tb();
    endtask

    task do_qreq_handshake(virtual cdie_pm_vc_dielet_pm_if vif);
        `CALL_TASK_WITH_TIMEOUT(wait(vif.QREQn == 0), 5)
        vif.QACCEPTn = 0;

    endtask

    task do_iso_handshake(virtual cdie_pm_vc_dielet_pm_if vif);
        `CALL_TASK_WITH_TIMEOUT(wait(vif.iso_req_b == 0), 5)
        vif.iso_ack_b = 0;
    endtask

endclass



module cdie_pm_vc_global_reset_test ();

    initial begin
        run_test("cdie_pm_vc_global_reset_test");
    end

endmodule
