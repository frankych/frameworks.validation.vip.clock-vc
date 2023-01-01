class pmsb_reg_read_sequence extends base_pmsb_sequence;

    `uvm_object_utils(pmsb_reg_read_sequence)

    rand logic [15:0] addr;
    rand iosfsbm_cm_uvm::opcode_t read_opcode;

    constraint opcode_c {
        read_opcode inside {OP_CRRD, OP_MRD, OP_CFGRD};
    }

    function new(string name="");
        super.new(name);
    endfunction

    task body();

        register_addr = '{addr[7:0], addr[15:8]};
        opcode = read_opcode;

        send_regio_read();

    endtask

    task send_regio_read();
        iosfsbm_cm_uvm::regio_xaction reg_read_txn;

        set_endpoints_for_hier_sb();
        extended_headers = '{8'h00, cfg.punit_to_dmu_sai, 8'h00, 8'h00};

        reg_read_txn = iosfsbm_cm_uvm::regio_xaction::type_id::create("reg_read_txn", null);
        reg_read_txn.set_cfg(val_pmsb_fabric.fabric_cfg_i.ep_cfg_i, val_pmsb_fabric.common_cfg_i);
        reg_read_txn.set_sequencer(val_pmsb_fabric.fbrcvc_sequencer);
        if(!reg_read_txn.randomize() with {
                    foreach(register_addr[i])
                        addr[i] == register_addr[i];
                    foreach(extended_headers[i])
                        ext_headers_per_txn[i] == extended_headers[i];
                    ext_headers_per_txn.size() == extended_headers.size();
                    addr.size() == register_addr.size();
                    EH == 1'b1;
                    sbe == 4'h0;
                    fbe == 4'hf;
                    opcode == read_opcode;
                    src_pid == svc_src_pid;
                    local_src_pid == cfg.punit_pmsb_portid[7:0];
                    dest_pid == svc_dest_pid;
                    local_dest_pid == dest_id[7:0];
                    xaction_class == iosfsbm_cm_uvm::NON_POSTED;
                })
            `uvm_fatal(get_type_name(), "Could not randomize transaction object")
        `uvm_send(reg_read_txn)
    endtask

endclass