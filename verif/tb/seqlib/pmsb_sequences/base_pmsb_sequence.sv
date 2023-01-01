class base_pmsb_sequence extends uvm_sequence;
    
    `uvm_object_utils(base_pmsb_sequence)
    
    iosfsbm_fbrc_uvm::iosfsbm_fbrcvc val_pmsb_fabric;
    cdie_clk_vc_config cfg;
    logic [15:0] dest_id, src_id;
    logic [7:0] svc_dest_pid, svc_src_pid;
    logic [7:0] extended_headers[4];
    logic [7:0] register_data[];
    logic [7:0] register_addr[];
    logic [7:0] opcode;
    
    function new(string name="");
        super.new(name);
        if(!uvm_config_db#(iosfsbm_fbrc_uvm::iosfsbm_fbrcvc)::get(null, "cdie_clk_vc_val_env", "val_pmsb_fabric", val_pmsb_fabric))
            `uvm_fatal(get_type_name(), "Unable to find the val_pmsb_fabric in the uvm_config_db")
        if(!uvm_config_db #(cdie_clk_vc_config)::get(null, "", "cdie_clk_vc_config", cfg))
            `uvm_fatal(get_type_name(), "Unable to get cdie_clk_vc_config from uvm_config_db")
            
        dest_id = cfg.dmu_pmsb_portid;
        src_id = cfg.punit_pmsb_portid;
    endfunction
    
    function void set_endpoints_for_hier_sb();
        if (val_pmsb_fabric.fbrcvc_sequencer.m_ep_cfg.global_intf_en == 0) begin
            svc_dest_pid = dest_id[7:0];
            svc_src_pid = src_id[7:0];
        end else begin
            svc_dest_pid = dest_id[15:8];
            svc_src_pid = src_id[15:8];
        end
    endfunction
    
    task send_regio_txn();
        iosfsbm_cm_uvm::regio_xaction reg_write_txn;        
        xaction_class_e txn_class;
        
        set_endpoints_for_hier_sb();
        extended_headers = '{8'h00, cfg.punit_to_dmu_sai, 8'h00, 8'h00};
        
        
        if (opcode == iosfsbm_cm_uvm::OP_CFGWR)
            txn_class = iosfsbm_cm_uvm::NON_POSTED;
        else
            txn_class = iosfsbm_cm_uvm::POSTED;
        
        reg_write_txn = iosfsbm_cm_uvm::regio_xaction::type_id::create("reg_write_txn", null);
        reg_write_txn.set_cfg(val_pmsb_fabric.fabric_cfg_i.ep_cfg_i, val_pmsb_fabric.common_cfg_i);
        reg_write_txn.set_sequencer(val_pmsb_fabric.fbrcvc_sequencer);
        if(!reg_write_txn.randomize() with {
                    foreach(register_addr[i])
                    addr[i] == register_addr[i];
                    foreach(register_data[i])
                    data[i] == register_data[i];
                    foreach(extended_headers[i])
                    ext_headers_per_txn[i] == extended_headers[i];
                    ext_headers_per_txn.size() == extended_headers.size();
                    data.size() == register_data.size();
                    addr.size() == register_addr.size();
                    EH == 1'b1;
                    sbe == 4'h0;
                    fbe == 4'hf;
                    opcode == local::opcode;
                    src_pid == svc_src_pid;
                    local_src_pid == cfg.punit_pmsb_portid[7:0];
                    dest_pid == svc_dest_pid;
                    local_dest_pid == cfg.dmu_pmsb_portid[7:0];
                    xaction_class == txn_class;
                })
            `uvm_fatal(get_type_name(), "Could not randomize transaction object")
        `uvm_send(reg_write_txn)
    endtask
    
    task send_simple_txn();
        iosfsbm_cm_uvm::simple_xaction txn;
        
        set_endpoints_for_hier_sb();
        extended_headers = '{8'h00, cfg.punit_to_dmu_sai, 8'h00, 8'h00};
        
        txn = iosfsbm_cm_uvm::simple_xaction::type_id::create("simple_txn", null);
        txn.set_cfg(val_pmsb_fabric.fabric_cfg_i.ep_cfg_i, val_pmsb_fabric.common_cfg_i);
        txn.set_sequencer(val_pmsb_fabric.fbrcvc_sequencer);
        if(!txn.randomize() with {
            foreach(extended_headers[i])
            ext_headers_per_txn[i] == extended_headers[i];
            ext_headers_per_txn.size() == extended_headers.size();
            EH == 1'b1;
            opcode == local::opcode;
            src_pid == svc_src_pid;
            local_src_pid == cfg.punit_pmsb_portid[7:0];
            dest_pid == svc_dest_pid;
            local_dest_pid == cfg.dmu_pmsb_portid[7:0];
            xaction_class == iosfsbm_cm_uvm::POSTED;
        })
            `uvm_fatal(get_type_name(), "Could not randomize transaction object")
        `uvm_send(txn)
    endtask
    
endclass
