class cdie_pm_vc_cbo_response_test extends cdie_pm_vc_cold_boot_test;

    `uvm_component_utils(cdie_pm_vc_cbo_response_test)

    function new (string name="cdie_pm_vc_cbo_response_test", uvm_component parent=null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction

    function void connect();
        super.connect();
    endfunction

    virtual task test_content();
        send_cbo_drain_msg_sequence drain_seq;
        send_ncu_pcu_msg_sequence ncu_pcu_msg_seq;
        super.test_content();

        drain_seq = new();
        drain_seq.start(null);

        `CALL_TASK_WITH_TIMEOUT(wait_for_drain_acks(), 5)

        ncu_pcu_msg_seq = new();
        ncu_pcu_msg_seq.start(null);

        `CALL_TASK_WITH_TIMEOUT(wait_for_ncu_ack(), 5)
    endtask

    virtual task wait_for_drain_acks();

        foreach(cdie_config.cdie_cbo_portids[i]) begin
            iosfsbm_cm_uvm::xaction txn;
            iosfsbm_cm_uvm::simple_xaction simple_txn;
            `uvm_info(get_type_name(), $sformatf("Checking for CBO_ACK from portID %h",cdie_config.cdie_cbo_portids[i]), UVM_LOW)
            do gpsb_fifo.get(txn);
            while (!($cast(simple_txn, txn) && simple_txn.opcode == cdie_config.cbo_drain_ack_opcode && port_id_matches(simple_txn, cdie_config.cdie_cbo_portids[i])));

        end

    endtask

    function bit port_id_matches(iosfsbm_cm_uvm::simple_xaction simple_txn, logic[15:0] expected_port_id);
        if (cdie_config.vc_ep_is_global)
            return (simple_txn.local_src_pid == expected_port_id[7:0]);
        else
            return simple_txn.src_pid == expected_port_id[7:0];

    endfunction

    virtual task wait_for_ncu_ack();

        iosfsbm_cm_uvm::xaction txn;
        iosfsbm_cm_uvm::regio_xaction regio_txn;
        do gpsb_fifo.get(txn);
        while (!($cast(regio_txn, txn) && regio_txn.opcode == iosfsbm_cm_uvm::OP_CRWR && regio_txn.data[3] == 'h80 && regio_txn.addr[0] == cdie_config.ncu_lock_control_status_addr[7:0] && regio_txn.addr[1] == cdie_config.ncu_lock_control_status_addr[15:8]));

    endtask



endclass

module cdie_pm_vc_cbo_response_test ();
    initial begin
        run_test("cdie_pm_vc_cbo_response_test");
    end
endmodule
