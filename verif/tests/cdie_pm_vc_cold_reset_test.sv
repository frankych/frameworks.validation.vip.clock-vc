class cdie_pm_vc_cold_reset_test extends cdie_pm_vc_cold_boot_test;

    `uvm_component_utils(cdie_pm_vc_cold_reset_test)

    reset_send_go_s1_rw send_go_s1_rw;
    reset_send_reset_warn send_reset_warn;

    uvm_tlm_analysis_fifo #(iosfsbm_cm_uvm::xaction) sb_fifo;

    function new (string name="cdie_pm_vc_cold_reset_test", uvm_component parent=null);
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
        $display("mooga starting test");
        send_go_s1_rw = new("sen_go_s1_rw");
        send_go_s1_rw.start(null);
        `CALL_TASK_WITH_TIMEOUT(wait_for_ack_sx(), 5)
        send_reset_warn = new("send_reset_warn");
        send_reset_warn.start(null);
        `CALL_TASK_WITH_TIMEOUT(wait_for_reset_warn_ack(), 5)
        $display("done with reset warn ack");
        do_qreq_handshake(idi_dielet_vif);
        $display("right before warm boot trigger deassertion");
        pm_vif.warm_boot_trigger = 0;
        do_qreq_handshake(gpsb_dielet_vif);
        do_qreq_handshake(pmsb_dielet_vif);
        `CALL_TASK_WITH_TIMEOUT(wait(idi_dielet_vif.coherent_traffic_req == 0), 1);
        pm_vif.cold_boot_trigger = 'b0;
        do_iso_handshake(pmsb_dielet_vif);
        do_iso_handshake(gpsb_dielet_vif);
        `CALL_TASK_WITH_TIMEOUT(wait(pm_vif.local_half_bridge_rst_b_sync == 0), 1);
        do_iso_handshake(idi_dielet_vif);
        pm_vif.early_boot_pd_on = 'b0;
        delay_for_tb();

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

    task do_qreq_handshake(virtual cdie_pm_vc_dielet_pm_if vif);
        $display("about to wait for a qreq");
        `CALL_TASK_WITH_TIMEOUT(wait(vif.QREQn == 0), 1)
        $display("done with wait for a qreq");
        vif.QACCEPTn = 0;
        $display("done with task");
    endtask

    task do_iso_handshake(virtual cdie_pm_vc_dielet_pm_if vif);
        `CALL_TASK_WITH_TIMEOUT(wait(vif.iso_req_b == 0), 1)
        vif.iso_ack_b = 0;
    endtask
endclass



module cdie_pm_vc_cold_reset_test ();

    initial begin
        run_test("cdie_pm_vc_cold_reset_test");
    end

endmodule
