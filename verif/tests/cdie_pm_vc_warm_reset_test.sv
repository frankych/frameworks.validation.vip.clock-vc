class cdie_pm_vc_warm_reset_test extends cdie_pm_vc_cold_boot_test;

    `uvm_component_utils(cdie_pm_vc_warm_reset_test)

    reset_send_go_s1_rw send_go_s1_rw;
    reset_send_reset_warn send_reset_warn;
    send_cmpd_msg_sequence cmpd_txn;

    uvm_tlm_analysis_fifo #(iosfsbm_cm_uvm::xaction) sb_fifo;
    uvm_tlm_analysis_fifo #(iosfsbm_cm_uvm::xaction) gpsb_fifo2;

    function new (string name="cdie_pm_vc_warm_reset_test", uvm_component parent=null);
        super.new (name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        sb_fifo = new("sb_fifo", this);
        gpsb_fifo2 = new("gpsb_fifo2", this);
    endfunction

    function void connect();
        super.connect();
        val_env.val_pmsb_agent.tx_ap.connect(this.sb_fifo.analysis_export);
        val_env.val_gpsb_agent.tx_ap.connect(this.gpsb_fifo2.analysis_export);
    endfunction

    task delay_for_tb();
        #5ns;
    endtask

    virtual task test_content();
        super.test_content();
        delay_for_tb();
        send_go_s1_rw = new("sen_go_s1_rw");
        send_go_s1_rw.start(null);
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
        verify_cold_reset_does_not_happen();
        #100ns;
    endtask

    task respond_to_cr_reads();
        iosfsbm_cm_uvm::xaction txn;
        
        fork begin
            do begin
                gpsb_fifo2.get(txn);
                if (txn.opcode == iosfsbm_cm_uvm::OP_CRRD) begin
                    send_cmpd();
                end
            end while (1);
        end
        join_none
        
    endtask

    task send_cmpd();
        cmpd_txn = new("cmpd_txn");
        cmpd_txn.randomize();
        cmpd_txn.start(null);
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



module cdie_pm_vc_warm_reset_test ();

    initial begin
        run_test("cdie_pm_vc_warm_reset_test");
    end

endmodule
