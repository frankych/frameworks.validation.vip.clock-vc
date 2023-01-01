class cdie_pm_vc_user_svid_test extends cdie_pm_vc_cold_boot_test;

    `uvm_component_utils(cdie_pm_vc_user_svid_test)

    logic [63:0] completion_data;

    function new (string name="cdie_pm_vc_user_svid_test", uvm_component parent=null);
        super.new (name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction

    function void connect();
        super.connect();
        val_env.vc_env.gpsb_to_py_port.set_dest_portid('ha0);
    endfunction

    task delay_for_tb();
        #5ns;
    endtask

    virtual task test_content();
        super.test_content();
        
        request_user_svid_seq();
        wait_for_user_svid_seq_sent(pmsb_fifo);
        check_svid_data();
        
    endtask
    
    task request_user_svid_seq();
        cdie_send_user_svid_seq svid_seq;
        svid_seq = new();
        svid_seq.randomize() with {enable_alert == 'b1;
                                   command == SETVID_FAST;
                                   payload == 'b1;};
        svid_seq.start(null);
        
    endtask
    
    task wait_for_user_svid_seq_sent(uvm_tlm_analysis_fifo #(iosfsbm_cm_uvm::xaction) fifo);
        logic [63:0] data;
        iosfsbm_cm_uvm::xaction txn;
        iosfsbm_cm_uvm::regio_xaction reg_txn;
        do begin fifo.get(txn); end
        while(!($cast(reg_txn, txn) && reg_txn.opcode == iosfsbm_cm_uvm::OP_CRWR 
                                    && reg_txn.addr[0] == cdie_config.svid_vr_req_cdie_addr[7:0] 
                                    && reg_txn.addr[1] == cdie_config.svid_vr_req_cdie_addr[15:8]));

        completion_data = {reg_txn.data[3], reg_txn.data[2], reg_txn.data[1], reg_txn.data[0]};
        if(reg_txn.data.size() == 4) begin
            completion_data[63:32] = 'h0;
        end else begin
            completion_data[63:32] = {reg_txn.data[7], reg_txn.data[6], reg_txn.data[5], reg_txn.data[4]};
        end
    endtask
    
    task check_svid_data();
        logic [63:0] expected_data;
        expected_data = 'h80_03_01_01;
        if (completion_data != expected_data)
            `uvm_error(get_type_name(), $sformatf("Didn't receive the correct svid data: %h", completion_data))
    endtask

endclass



module cdie_pm_vc_user_svid_test ();

    initial begin
        run_test("cdie_pm_vc_user_svid_test");
    end

endmodule
