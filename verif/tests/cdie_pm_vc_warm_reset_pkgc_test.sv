class cdie_pm_vc_warm_reset_pkgc_test extends cdie_pm_vc_dc_base_test;

    `uvm_component_utils(cdie_pm_vc_warm_reset_pkgc_test)

    reset_send_go_s1_rw send_go_s1_rw;
    reset_send_reset_warn send_reset_warn;

    uvm_tlm_analysis_fifo #(iosfsbm_cm_uvm::xaction) sb_fifo;

    function new (string name="cdie_pm_vc_warm_reset_test", uvm_component parent=null);
        super.new (name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        sb_fifo = new("sb_fifo", this);
    endfunction

    function void connect();
        super.connect();
        val_env.val_pmsb_agent.tx_ap.connect(this.sb_fifo.analysis_export);
        val_env.val_pmsb_agent.tx_ap.connect(this.pmsb_diec_state_fifo.analysis_export);
    endfunction

    virtual task test_content();
        super.test_content();
        delay_for_tb();
        val_env.vc_env.power_state_response_handler_set_max_state(DC2_1);
        request_dc_seq = new();
        request_dc_seq.randomize() with {
            state == DC2_1;
        };
        request_dc_seq.start(null);
        do_dc0_to_dc1();
        do_dc1_to_dc2_1();
        send_go_s1_rw = new("sen_go_s1_rw");
        send_go_s1_rw.start(null);
        do_dc2_1_to_dc1();
        `CALL_TASK_WITH_TIMEOUT(wait_for_ack_sx(), 5)
        send_reset_warn = new("send_reset_warn");
        send_reset_warn.start(null);
        `CALL_TASK_WITH_TIMEOUT(wait_for_reset_warn_ack(), 5)
        do_qreq_handshake(idi_dielet_vif);
        pm_vif.warm_boot_trigger = 0;
        do_qreq_handshake(gpsb_dielet_vif);
        do_qreq_handshake(pmsb_dielet_vif);
        `CALL_TASK_WITH_TIMEOUT(wait(idi_dielet_vif.coherent_traffic_req == 0), 5);
        delay_for_tb();
        pm_vif.warm_boot_trigger = 'b1;
        `CALL_TASK_WITH_TIMEOUT(wait(pm_vif.cdie_current_state == DC0), 5)
        verify_cold_reset_does_not_happen();
    endtask

    task wait_for_simple_message(boot_reset_opcodes_t opcode);
        iosfsbm_cm_uvm::xaction txn;
        iosfsbm_cm_uvm::simple_xaction simple_txn;
        bit done = 0;

        do begin
            sb_fifo.get(txn);
            if (txn.xaction_type == iosfsbm_cm_uvm::SIMPLE) begin
                $cast(simple_txn, txn);
                if (simple_txn.opcode === opcode)
                    done = 1;
            end
        end while (!done);
    endtask

    task wait_for_ack_sx();
        wait_for_simple_message(cdie_pm_vc_env_pkg::ack_sx);
    endtask

    task wait_for_reset_warn_ack();
        wait_for_simple_message(cdie_pm_vc_env_pkg::reset_warn_ack);
    endtask

    task verify_cold_reset_does_not_happen();
        fork begin

                fork
                    begin
                        wait(gpsb_dielet_vif.iso_req_b == 0);
                        `uvm_error (get_type_name(), "ISO req asserted even though cold boot trigger was not deasserted");
                    end
                    #2us;
                join_any
                disable fork;
            end
        join
    endtask
    
    task do_qreq_handshake(virtual cdie_pm_vc_dielet_pm_if vif);
        `CALL_TASK_WITH_TIMEOUT(wait(vif.QREQn == 0), 5)
        vif.QACCEPTn = 0;
    endtask
    
endclass


module cdie_pm_vc_warm_reset_pkgc_test ();

    initial begin
        run_test("cdie_pm_vc_warm_reset_pkgc_test");
    end

endmodule
