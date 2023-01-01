class cdie_pm_vc_dvfs_test extends cdie_pm_vc_dc6_test;

    `uvm_component_utils(cdie_pm_vc_dvfs_test)
    dvfs_send_wp_seq send_wp_req;

    function new (string name="cdie_pm_vc_dvfs_test", uvm_component parent=null);
        super.new(name, parent);
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

        test_simple_dvfs();
        test_dvfs_not_sent_in_dc6();
        test_dvfs_not_sent_entering_dc6();

    endtask

    task test_simple_dvfs();
        send_wp();
        check_dvfs_completes();
    endtask

    task test_dvfs_not_sent_in_dc6();

        test_simple_dvfs();

        request_dc_seq = new();
        request_dc_seq.randomize() with {
            state == DC6;
        };
        request_dc_seq.start(null);
        do_dc0_to_dc1();
        do_dc1_to_dc2_2('b1);
        do_dc2_2_to_dc6();

        send_wp();
        #10ns;
        pmsb_dielet_vif.QACTIVE = 1;
        #10ns;
        do_dc6_to_dc2_2();

        fork begin
                fork
                    begin
                        wait(pm_vif.cdie_current_state == cdie_pm_vc_env_pkg::DC2_2);
                    end
                    begin
                        wait_for_wp_ack();
                        `uvm_error(get_type_name(), "Received WP ack while CDIE was in DC state")
                    end
                join_any
                disable fork;
            end
        join
        check_dvfs_completes();
    endtask

    task test_dvfs_not_sent_entering_dc6();
        pmsb_dielet_vif.QACTIVE = 0;
        fork
            do_dc2_2_to_dc6();
            begin
                wait_for_update_status(DC6);
                wait_for_update_status_valid();
                #1010ns;
                send_wp();
            end
        join
        verify_no_wp_is_sent();

        request_dc_seq = new();
        request_dc_seq.randomize() with {
            state == DC0;
        };
        request_dc_seq.start(null);
        pmsb_dielet_vif.QACTIVE = 1;
        do_dc6_to_dc2_2();
        check_dvfs_completes();
        do_dc2_2_to_dc1(1);
        do_dc1_to_dc0();
    endtask

    virtual task wait_for_wp_ack();
        iosfsbm_cm_uvm::xaction txn;
        iosfsbm_cm_uvm::simple_xaction simple_txn;

        do gpsb_fifo.get(txn);
        while (!($cast(simple_txn, txn) && simple_txn.opcode == cdie_config.wp_req_opcode && simple_txn.misc == 'h2));
    endtask

    task send_wp();
        logic [7:0] wp_data_update [6] = '{'h2, 'h1, 'h3, 'h4, 'h5, 'h6};

        send_wp_req = new("send_wp_req");
        send_wp_req.randomize() with {
            foreach(wp_data[0][i])
                wp_data[0][i] == wp_data_update[i];
            sub_opcode == 'b1;
        };
        send_wp_req.start(null);

    endtask

    task check_dvfs_completes();
        `CALL_TASK_WITH_TIMEOUT(wait_for_wp_ack(), 20);

        pm_vif.go_prep_unprep = 1'b1;
        `CALL_TASK_WITH_TIMEOUT(wait(pm_vif.go_prep_unprep_ack == 1'b1), 1)
        pm_vif.go_incgb_decgb_req = 1'b1;
        `CALL_TASK_WITH_TIMEOUT(wait(pm_vif.go_incgb_decgb_ack == 1'b1), 1)
        pm_vif.go_incgb_decgb_req = 1'b0;
        `CALL_TASK_WITH_TIMEOUT(wait(pm_vif.go_incgb_decgb_ack == 1'b0), 1)
        pm_vif.go_prep_unprep = 1'b0;
        `CALL_TASK_WITH_TIMEOUT(wait(pm_vif.go_prep_unprep_ack == 1'b0), 1)
    endtask

    task verify_no_wp_is_sent();
        fork begin
                fork
                    begin
                        #5us;
                    end
                    begin
                        wait_for_wp_ack();
                        `uvm_error(get_type_name(), "Received WP ack while CDIE was in DC state")
                    end
                join_any
                disable fork;
            end
        join
    endtask

endclass

module cdie_pm_vc_dvfs_test ();
    initial begin
        run_test("cdie_pm_vc_dvfs_test");
    end
endmodule
