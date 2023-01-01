class cdie_pm_vc_svid_generator_test extends cdie_pm_vc_warm_reset_test;

    `uvm_component_utils(cdie_pm_vc_svid_generator_test)

    bit stimulus_recieved = 0;

    function new (string name="cdie_pm_vc_svid_generator_test", uvm_component parent=null);
        super.new (name, parent);
    endfunction

    function void connect();
        super.connect();
        cdie_config.svid_random_stimulus_enable = 1;
        cdie_config.svid_random_stimulus_delay_min_in_ps = 1000;
        cdie_config.svid_random_stimulus_delay_max_in_ps = 2000;
    endfunction

    virtual task test_content();
        fork
            forever begin
                wait_for_random_svid_stimulus(pmsb_fifo);
            end
        join_none
        
        do_cold_boot();

        send_go_s1_rw = new("sen_go_s1_rw");
        send_go_s1_rw.start(null);
        stimulus_recieved = 0;
        
        fork
            begin
                fork
                    begin

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
                    end
                    begin
                        wait(stimulus_recieved == 1)
                        `uvm_fatal(get_type_name(), "Random svid stimulus was sent during warm reset, which is not allowed")
                    end
                join_any disable fork;
            end
        join
        stimulus_recieved = 0;

        `CALL_TASK_WITH_TIMEOUT(wait(stimulus_recieved == 1), 5)
    endtask

    task wait_for_random_svid_stimulus(uvm_tlm_analysis_fifo #(iosfsbm_cm_uvm::xaction) fifo);
        logic [63:0] data;
        iosfsbm_cm_uvm::xaction txn;
        iosfsbm_cm_uvm::regio_xaction regio_txn;

        do begin
            fifo.get(txn);
        end
        while(!($cast(regio_txn, txn) && regio_txn.opcode  == iosfsbm_cm_uvm::OP_CRWR
                && regio_txn.addr[0] == cdie_config.svid_vr_req_cdie_addr[7:0]
                && regio_txn.addr[1] == cdie_config.svid_vr_req_cdie_addr[15:8]
                && !(regio_txn.data[0] == 'h01 && regio_txn.data[1] == 'h01 && regio_txn.data[2] == 'h03 && regio_txn.data[3] == 'h80)
                && !(regio_txn.data[0] == 'h10 && regio_txn.data[1] == 'h07 && regio_txn.data[2] == 'h03 && regio_txn.data[3] == 'h80)));
        stimulus_recieved = 1;
        send_svid_vr_response_transmit_done();

    endtask

endclass



module cdie_pm_vc_svid_generator_test ();

    initial begin
        run_test("cdie_pm_vc_svid_generator_test");
    end

endmodule
