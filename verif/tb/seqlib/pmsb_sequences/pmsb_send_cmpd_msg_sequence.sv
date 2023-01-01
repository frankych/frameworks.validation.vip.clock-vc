class pmsb_send_cmpd_msg_sequence extends base_pmsb_sequence;

    `uvm_object_utils(pmsb_send_cmpd_msg_sequence)

    function new(string name="");
        super.new(name);
    endfunction

    task body();
        dest_id = cfg.dmu_pmsb_portid;
        src_id = cfg.punit_pmsb_portid;
        send_msgd_txn();
    endtask

    task send_msgd_txn();
        iosfsbm_cm_uvm::comp_xaction txn;

        register_data = new[4]('{'h0, 'h0, 'h0, 'h40});
        extended_headers = '{8'h00, cfg.punit_to_dmu_sai, 8'h00, 8'h00};
        set_endpoints_for_hier_sb();

        txn = comp_xaction::type_id::create("txn", null);
        txn.set_cfg(val_pmsb_fabric.fabric_cfg_i.ep_cfg_i, val_pmsb_fabric.common_cfg_i);
        txn.set_sequencer(val_pmsb_fabric.fbrcvc_sequencer);

        if (!txn.randomize() with {
                    dest_pid == svc_dest_pid;
                    local_dest_pid == dest_id[7:0];
                    src_pid == svc_src_pid;
                    local_src_pid == src_id[7:0];
                    opcode == cfg.cmpd_opcode;
                    EH == 1;
                    foreach(extended_headers[i])
                        ext_headers_per_txn[i] == extended_headers[i];
                    ext_headers_per_txn.size() == extended_headers.size();
                    xaction_type == iosfsbm_cm_uvm::COMP;
                    xaction_class == iosfsbm_cm_uvm::POSTED;
                    foreach(register_data[i])
                        data[i] == register_data[i];
                    data.size() == register_data.size();
                }) `uvm_error(get_type_name(), "Could not randomize iosf sequence for sending cmpd msg");
        `uvm_send(txn);

    endtask

endclass