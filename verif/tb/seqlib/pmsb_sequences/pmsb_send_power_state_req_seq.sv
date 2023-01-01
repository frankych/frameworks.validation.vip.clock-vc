class pkgc_send_power_state_req extends base_pmsb_sequence;

    `uvm_object_utils(pkgc_send_power_state_req)

    rand cdie_cstate_t max_state, min_state;

    function new(string name="");
        super.new(name);
    endfunction

    task body();
        register_addr = new[2]('{cfg.power_state_req_soc2cdie_addr[7:0], cfg.power_state_req_soc2cdie_addr[15:8]});
        register_data = new[4]('{max_state,  min_state, 8'h00, 8'h00});
        opcode = iosfsbm_cm_uvm::OP_CRWR;

        send_regio_txn();
    endtask
endclass
