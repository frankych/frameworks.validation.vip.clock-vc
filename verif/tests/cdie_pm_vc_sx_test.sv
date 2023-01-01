`define TEST_SX(sleep_to_test) \
    delay_for_tb(); \
    super.test_content(); \
    send_go_s1_temp = new("sen_go_s1_temp"); \
    send_go_s1_temp.start(null); \
    `CALL_TASK_WITH_TIMEOUT(wait_for_ack_sx(), 5) \
    send_go_``sleep_to_test = new(`"send_go_``sleep_to_test`"); \
    send_go_``sleep_to_test.start(null); \
    `CALL_TASK_WITH_TIMEOUT(wait_for_ack_sx(), 5) \
    do_qreq_handshake(idi_dielet_vif); \
    pm_vif.warm_boot_trigger = 0; \
    #10ns; \
    do_qreq_handshake(gpsb_dielet_vif); \
    do_qreq_handshake(pmsb_dielet_vif); \
    pm_vif.cold_boot_trigger = 0; \
    do_iso_handshake(pmsb_dielet_vif); \
    do_iso_handshake(gpsb_dielet_vif); \
    do_iso_handshake(idi_dielet_vif); \
    pm_vif.early_boot_pd_on = 0; \
    delay_for_tb();

class cdie_pm_vc_sx_test extends cdie_pm_vc_cold_boot_test;

    `uvm_component_utils(cdie_pm_vc_sx_test)

    reset_send_go_s1_temp send_go_s1_temp;
    reset_send_go_s3 send_go_s3;
    reset_send_go_s4 send_go_s4;
    reset_send_go_s5 send_go_s5;

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
    endfunction

    task delay_for_tb();
        #5ns;
    endtask

    virtual task test_content();
        run_s3_test();
        run_s4_test();
        run_s5_test();
    endtask

    task run_s3_test();
        `TEST_SX(s3)
    endtask

    task run_s4_test();
        `TEST_SX(s4)
    endtask

    task run_s5_test();
        `TEST_SX(s5)
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
        `CALL_TASK_WITH_TIMEOUT(wait(vif.QREQn == 0), 5)
        vif.QACCEPTn = 0;

    endtask

    task do_iso_handshake(virtual cdie_pm_vc_dielet_pm_if vif);
        `CALL_TASK_WITH_TIMEOUT(wait(vif.iso_req_b == 0), 5)
        vif.iso_ack_b = 0;
    endtask
endclass



module cdie_pm_vc_sx_test ();

    initial begin
        run_test("cdie_pm_vc_sx_test");
    end

endmodule
