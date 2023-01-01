class cdie_svid_ownership_semaphore_cb extends iosfsbm_cm_uvm::opcode_cb;

    `uvm_component_utils(cdie_svid_ownership_semaphore_cb)

    iosfsbm_cm_uvm::comp_xaction cmpd_tx_xaction;
    iosfsbm_cm_uvm::regio_xaction regio_rx_xaction;
    cdie_clk_vc_config cfg;
    logic [7:0] register_data[];

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function iosfsbm_cm_uvm::comp_xaction execute_cb(string name, iosfsbm_cm_uvm::ep_cfg m_ep_cfg, iosfsbm_cm_uvm::common_cfg m_common_cfg,
            bit[1:0] rsp_field, iosfsbm_cm_uvm::xaction rx_xaction);
        cfg = cdie_clk_vc_config::type_id::create("cfg");
        if (!($cast(regio_rx_xaction, rx_xaction)))
            `uvm_error(get_type_name(), "Failed to cast xaction to regio_xaction")
        if (regio_rx_xaction.addr[0] == cfg.svid_ownership_semaphore_addr[7:0] && regio_rx_xaction.addr[1] == cfg.svid_ownership_semaphore_addr[15:8]) begin
            create_cmpd_xaction(m_ep_cfg, m_common_cfg, rx_xaction);
            return cmpd_tx_xaction;
        end else begin
            return null;
        end
    endfunction

    function void create_cmpd_xaction(iosfsbm_cm_uvm::ep_cfg m_ep_cfg, iosfsbm_cm_uvm::common_cfg m_common_cfg, iosfsbm_cm_uvm::xaction rx_xaction);
        cmpd_tx_xaction = iosfsbm_cm_uvm::comp_xaction::type_id::create("cmpd_tx_xaction");
        cmpd_tx_xaction.set_cfg(m_ep_cfg, m_common_cfg);
        register_data = new[4]('{'h1, 'h0, 'h0, 'h0});
        if(!cmpd_tx_xaction.randomize() with {
                    xaction_class   == iosfsbm_cm_uvm::POSTED;
                    opcode          == iosfsbm_cm_uvm::OP_CMPD;
                    dest_pid        == rx_xaction.src_pid;
                    local_dest_pid  == rx_xaction.local_src_pid;
                    src_pid         == rx_xaction.dest_pid;
                    local_src_pid   == rx_xaction.local_dest_pid;
                    tag             == rx_xaction.tag;
                    rsp             == iosfsbm_cm_uvm::RSP_SUCCESSFUL;
                    EH              == 1'b1;
                    ext_headers_per_txn.size() ==  4;
                    ext_headers_per_txn[0] == 8'h0;
                    ext_headers_per_txn[1] == cfg.punit_to_dmu_sai;
                    ext_headers_per_txn[2] == 8'h0;
                    ext_headers_per_txn[3] == 8'h0;
                    foreach(register_data[i])
                        data[i] == register_data[i];
                    data.size() == register_data.size();
                })
            `uvm_fatal(get_type_name(), "Generation of CMPD Xaction failed")
    endfunction

endclass
