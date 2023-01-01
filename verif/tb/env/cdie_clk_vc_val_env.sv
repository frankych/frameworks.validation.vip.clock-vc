import cdie_clk_vc_env_pkg::*;
import iosfsbm_fbrc_uvm::*;
import iosfsbm_agent_uvm::*;

class cdie_clk_vc_val_env extends uvm_env;

    `uvm_component_utils(cdie_clk_vc_val_env)

    cdie_clk_vc_env vc_env;
    iosfsbm_fbrcvc val_gpsb_fabric;
    iosfsbm_fbrcvc val_pmsb_fabric;
    iosfsbm_agtvc val_gpsb_agent;
    iosfsbm_agtvc val_pmsb_agent;
    cdie_pmsb_watcher pmsb_watcher;
    cdie_svid_ownership_semaphore_cb svid_semaphore_cb;
    iosfsbm_cm_uvm::iosfsbc_sequencer gpsb_agt_seqr, pmsb_agt_seqr;
    logic [7:0] dmu_gpsb_ids [$], dmu_pmsb_ids[$], punit_gpsb_ids[$], punit_pmsb_ids[$];

    function new(string name, uvm_component parent);
        super.new(name, parent);
        vc_env = cdie_clk_vc_env::type_id::create("env",this);
    endfunction

    function void build();
        super.build();
        pmsb_watcher = cdie_pmsb_watcher::type_id::create("pmsb_watcher", this);
        svid_semaphore_cb = cdie_svid_ownership_semaphore_cb::type_id::create("svid_semaphore_cb", this);
        create_fabric();
    endfunction

    function void connect();
        super.connect();
        vc_env.set_gpsb_vc(val_gpsb_agent);
        vc_env.set_pmsb_vc(val_pmsb_agent);
        uvm_config_db#(iosfsbm_fbrc_uvm::iosfsbm_fbrcvc)::set(null, "cdie_clk_vc_val_env", "val_pmsb_fabric", val_pmsb_fabric);
        uvm_config_db#(iosfsbm_fbrc_uvm::iosfsbm_fbrcvc)::set(null, "cdie_clk_vc_val_env", "val_gpsb_fabric", val_gpsb_fabric);
        gpsb_agt_seqr = val_gpsb_agent.get_sequencer();
        pmsb_agt_seqr = val_pmsb_agent.get_sequencer();
        val_gpsb_agent.agt_monitor_i.fab_agt_ap.connect(vc_env.cdie_gpsb_analysis_export);
        val_pmsb_agent.agt_monitor_i.fab_agt_ap.connect(vc_env.cdie_pmsb_analysis_export);
//        val_gpsb_agent.agt_monitor_i.agt_fab_ap.connect(gpsb_watcher.sideband_input_fifo.analysis_export);
        val_pmsb_agent.agt_monitor_i.agt_fab_ap.connect(pmsb_watcher.sideband_input_fifo.analysis_export);
    endfunction

    virtual function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        val_pmsb_fabric.register_user_cb(svid_semaphore_cb, {iosfsbm_cm_uvm::OP_CRRD});
        open_tracker_files();
    endfunction

    function void open_tracker_files();
        val_gpsb_fabric.open_tracker_file(
            .file_name("IOSF_GPSB_TRK.out"),
            .print_clock_state(1),
            .print_ism_state(1),
            .print_reset_state(1),
            .print_new_sip_format(1));
        val_gpsb_agent.open_tracker_file(
            .file_name("IOSF_GPSB_TRK.out"),
            .print_clock_state(1),
            .print_ism_state(1),
            .print_reset_state(1),
            .print_new_sip_format(1));
        val_pmsb_fabric.open_tracker_file(
            .file_name("IOSF_PMSB_TRK.out"),
            .print_clock_state(1),
            .print_ism_state(1),
            .print_reset_state(1),
            .print_new_sip_format(1));
        val_pmsb_agent.open_tracker_file(
            .file_name("IOSF_PMSB_TRK.out"),
            .print_clock_state(1),
            .print_ism_state(1),
            .print_reset_state(1),
            .print_new_sip_format(1));
    endfunction

    function void create_fabric();
        populate_valid_id_lists();
        create_fabric_vc();
        create_agent_vc();
    endfunction

    function void create_fabric_vc();

        create_fbrc_vc("val_gpsb_fabric", "gpsb_fabric_cfg", .my_portid(punit_gpsb_ids), .other_ports(dmu_gpsb_ids), .val_fabric(val_gpsb_fabric));
        create_fbrc_vc("val_pmsb_fabric", "pmsb_fabric_cfg", .my_portid(punit_pmsb_ids), .other_ports(dmu_pmsb_ids), .val_fabric(val_pmsb_fabric));
    endfunction

    function void create_fbrc_vc(string intf_name, string cfg_name, logic[7:0] my_portid[$], logic[7:0] other_ports[$], ref iosfsbm_fbrcvc val_fabric);
        iosfsbm_fbrc_uvm::fbrcvc_cfg cfg;
        val_fabric = iosfsbm_fbrcvc::type_id::create(intf_name, this);
        cfg = iosfsbm_fbrc_uvm::fbrcvc_cfg::type_id::create(cfg_name, this);
        $cast(cfg, set_ep_config(cfg));
        cfg.my_ports = my_portid;
        cfg.other_ports = other_ports;
        cfg.mcast_ports = {};
        cfg.set_intf_name(intf_name);
        val_fabric.fabric_cfg_i = cfg;
        cfg.extern_stimgen_mode = 0;
        uvm_config_object::set(this, intf_name, "fabric_cfg", cfg);
    endfunction

    function void create_agent_vc();
        create_agt_vc("val_gpsb_agent", "gpsb_agent_cfg", .my_portid(dmu_gpsb_ids), .other_ports(punit_gpsb_ids), .val_agent(val_gpsb_agent));
        create_agt_vc("val_pmsb_agent", "pmsb_agent_cfg", .my_portid(dmu_pmsb_ids), .other_ports(punit_pmsb_ids), .val_agent(val_pmsb_agent));
    endfunction

    function void create_agt_vc(string intf_name, string cfg_name, logic[7:0] my_portid[$], logic[7:0] other_ports[$], ref iosfsbm_agtvc val_agent);
        iosfsbm_agent_uvm::agtvc_cfg cfg;
        val_agent = iosfsbm_agtvc::type_id::create(intf_name, this);
        cfg = iosfsbm_agent_uvm::agtvc_cfg::type_id::create(cfg_name, this);
        $cast(cfg, set_ep_config(cfg));
        cfg.my_ports = my_portid;
        cfg.other_ports = other_ports;
        cfg.mcast_ports = {};
        cfg.set_intf_name(intf_name);
        val_agent.agent_cfg_i = cfg;
        cfg.extern_stimgen_mode = 1;
        uvm_config_object::set(this, intf_name, "agent_cfg", cfg);

    endfunction

    function iosfsbm_cm_uvm::agt_cfg_base set_ep_config(iosfsbm_cm_uvm::agt_cfg_base cfg);
        iosfsbm_cm_uvm::opcode_t all_valid_opcodes[$];
        all_valid_opcodes = get_all_valid_opcodes();
        cfg.set_iosfspec_ver(IOSF_12);
        cfg.randomize() with {
            payload_width == 32;
            mcast_ports.size == 0;
            supported_opcodes.size() == all_valid_opcodes.size();
            foreach(all_valid_opcodes[i])
                supported_opcodes[i] == all_valid_opcodes[i];
        };
        cfg.payload_width = 32;
        cfg.mcast_ports = {};
        cfg.use_mem = 0;
        cfg.mon_enabled = 1;
        cfg.mem_be_support = 1;
        cfg.disable_compmon = 1;
        cfg.is_active = UVM_ACTIVE;
        cfg.loopback_support = 1;
        cfg.ext_header_support = 1;
        cfg.num_tx_ext_headers = 1;
        cfg.ext_headers_per_txn = 1;
        cfg.ext_headers.push_back(32'h12345678);
        cfg.chk_enabled = 0; //FIXME
        cfg.cov_enabled = 0;
        cfg.global_intf_en = vc_env.cdie_clk_config.vc_ep_is_global;
        return cfg;
    endfunction

    typedef iosfsbm_cm_uvm::opcode_t opcode_queue[$];
    function opcode_queue get_all_valid_opcodes();
        iosfsbm_cm_uvm::opcode_t all_valid_opcodes[$];
        //registers, global:8'h0-8'hf ep:8'h10-8'h1f, RSVD 8'h08-8'h0f
        for (int i = 8'h0; i < 8'h08; i++)
            all_valid_opcodes.push_back(i);
        for (int i = 8'h10; i < 8'h20; i++)
            all_valid_opcodes.push_back(i);
        //completions
        for (int i = 8'h20; i < 8'h22; i++)
            all_valid_opcodes.push_back(i);
        //common usage, RSVD 8'h2f-8'h3f
        for (int i = 8'h28; i < 8'h2f; i++)
            all_valid_opcodes.push_back(i);
        //message with data, global iosf1.1, RSVD: 8'h56-8'h5f
        for (int i = 8'h40; i < 8'h56; i++)
            all_valid_opcodes.push_back(i);
        //message with data, ep iosf1.1
        for (int i = 8'h60; i < 8'h80; i++)
            all_valid_opcodes.push_back(i);
        //simple messages, global RSVD:8'h95-8'h9f
        for (int i = 8'h80; i < 8'h95; i++)
            all_valid_opcodes.push_back(i);
        //simple messages, ep
        for (int i = 8'ha0; i < 8'hff; i++)
            all_valid_opcodes.push_back(i);

        return all_valid_opcodes;
    endfunction

    function void populate_valid_id_lists();
        dmu_gpsb_ids.push_back(vc_env.cdie_clk_config.dmu_gpsb_portid[7:0]);
        if (vc_env.cdie_clk_config.dmu_gpsb_portid[7:0] != vc_env.cdie_clk_config.dmu_gpsb_portid[15:8])
            dmu_gpsb_ids.push_back(vc_env.cdie_clk_config.dmu_gpsb_portid[15:8]);
        dmu_gpsb_ids.push_back(vc_env.cdie_clk_config.cdie_ccf_multicast_portid[7:0]);
        dmu_gpsb_ids.push_back(vc_env.cdie_clk_config.cdie_ccf_pma_portid[7:0]);
        dmu_gpsb_ids.push_back(vc_env.cdie_clk_config.cdie_ncevents_gpsb_portid[7:0]);
        foreach(vc_env.cdie_clk_config.cdie_cbo_portids[i])
            dmu_gpsb_ids.push_back(vc_env.cdie_clk_config.cdie_cbo_portids[i][7:0]);

        dmu_pmsb_ids.push_back(vc_env.cdie_clk_config.dmu_pmsb_portid[7:0]);
        if (vc_env.cdie_clk_config.dmu_pmsb_portid[7:0] != vc_env.cdie_clk_config.dmu_pmsb_portid[15:8])
            dmu_pmsb_ids.push_back(vc_env.cdie_clk_config.dmu_pmsb_portid[15:8]);

        punit_gpsb_ids.push_back(vc_env.cdie_clk_config.punit_gpsb_portid[7:0]);
        if (vc_env.cdie_clk_config.punit_gpsb_portid[7:0] != vc_env.cdie_clk_config.punit_gpsb_portid[15:8])
            punit_gpsb_ids.push_back(vc_env.cdie_clk_config.punit_gpsb_portid[15:8]);

        punit_gpsb_ids.push_back(vc_env.cdie_clk_config.soc_ncevents_gpsb_portid[7:0]);

        punit_pmsb_ids.push_back(vc_env.cdie_clk_config.punit_pmsb_portid[7:0]);
        if (vc_env.cdie_clk_config.punit_pmsb_portid[7:0] != vc_env.cdie_clk_config.punit_pmsb_portid[15:8])
            punit_pmsb_ids.push_back(vc_env.cdie_clk_config.punit_pmsb_portid[15:8]);


    endfunction

endclass
