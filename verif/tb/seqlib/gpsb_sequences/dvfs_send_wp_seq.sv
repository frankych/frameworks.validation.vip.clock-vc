class dvfs_send_wp_seq extends base_gpsb_sequence;

    `uvm_object_utils(dvfs_send_wp_seq)

    rand logic [2:0] sub_opcode;
    rand logic [2:0] request_type[3];
    rand logic [2:0] rsvd [3];
    rand logic [1:0] param_type [3];
    rand logic [7:0] param_id [3];
    rand logic [7:0] wp_data [3][6];
    parameter bytes_in_payload = 4;
    parameter num_payloads = 6;

    constraint dvfs_wp_const {
        soft sub_opcode == 'b1;
        soft request_type[0] == 'h2;
        foreach(param_type[i]) {
            if (i == 0)
                soft param_type[i] == 'h0;
            else
                soft param_type[i] >= 'h0;
        }
        foreach(param_id[i]) {
            if (i == 0)
                soft param_id[i] == 'h0;
            else
                soft param_id[i] >= 'h0;
        }
        foreach(rsvd[i]) soft rsvd[i] == 'h0;
    }

    function new(string name="");
        super.new(name);
    endfunction

    task body();
        logic [7:0] data_bytes[num_payloads][bytes_in_payload];
        iosfsbm_cm_uvm::msgd_xaction txn;

        extended_headers = '{8'h00, cfg.punit_to_dmu_sai, 8'h00, 8'h00};

        foreach(data_bytes[i]) begin
            int mod_index = i/2;
            if (i % 2 == 0) begin
                data_bytes[i] = '{{param_type[mod_index], rsvd[mod_index], request_type[mod_index]}, param_id[mod_index], wp_data[mod_index][0], wp_data[mod_index][1]};
            end else begin
                data_bytes[i] = '{wp_data[mod_index][2], wp_data[mod_index][3], wp_data[mod_index][4], wp_data[mod_index][5]};
            end
        end

        set_endpoints_for_hier_sb();

        txn = msgd_xaction::type_id::create("txn", null);
        txn.set_cfg(val_gpsb_fabric.fabric_cfg_i.ep_cfg_i, val_gpsb_fabric.common_cfg_i);
        txn.set_sequencer(val_gpsb_fabric.fbrcvc_sequencer);

        if (!txn.randomize() with {
                    dest_pid == svc_dest_pid;
                    local_dest_pid == cfg.dmu_gpsb_portid[7:0];
                    src_pid == svc_src_pid;
                    local_src_pid == cfg.punit_gpsb_portid[7:0];
                    opcode == cfg.wp_req_opcode;
                    EH == 1;
                    xaction_type == iosfsbm_cm_uvm::MSGD;
                    xaction_class == iosfsbm_cm_uvm::POSTED;
                    foreach(data_bytes[i]) {
                        foreach(data_bytes[i][j]) {
                            data[i*bytes_in_payload + j] == data_bytes[i][j];
                        }
                    }
                    data.size == num_payloads * bytes_in_payload;
                    misc == {0, sub_opcode};
                    foreach(extended_headers[i])
                    ext_headers_per_txn[i] == extended_headers[i];
                    ext_headers_per_txn.size() == extended_headers.size();
                }) `uvm_error(get_type_name(), "Could not randomize iosf sequence for sending dvfs");
        `uvm_send(txn);

    endtask

endclass