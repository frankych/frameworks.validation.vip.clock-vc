// FIXME:  Have to hack this config file to only put 8 bits in the yaml because pydoh does not support
// hier SB right now.

class cdie_clk_vc_config extends uvm_object;

    `uvm_object_utils(cdie_clk_vc_config)

    logic toggle_clocks_during_dcstate = 1;
    bit vc_ep_is_global = 'b0;
    bit bypass_svid = 'b0;
    bit send_svid_alert_ready = 'b0;
    bit svid_random_stimulus_enable = 'b0;
    logic [7:0] svid_random_stimulus_set_vid_min = 'h0a;
    logic [7:0] svid_random_stimulus_set_vid_max = 'hff;
    logic [7:0] svid_random_stimulus_allowed_dc_states[$] = {DC0, DC1, DC2_1, DC2_2};
    
    logic [7:0] punit_to_dmu_sai = 'h1a;

    // PORT IDS
    logic [15:0] dmu_pmsb_portid = 'h0130;
    logic [7:0] cdie_bridge_pmsb_portid = 'h01;
    logic [15:0] punit_pmsb_portid = 'hf6f6;
    logic [15:0] dmu_gpsb_portid = 'hc7c7;
    logic [7:0] cdie_bridge_gpsb_portid = 'hc7;
    logic [15:0] punit_gpsb_portid = 'hf7f7;
    logic [15:0] soc_ncevents_gpsb_portid = 'hf8f8;
    logic [15:0] cdie_ncevents_gpsb_portid = 'ha0a0;
    logic [15:0] cdie_ncracu_gpsb_portid = 'h9f9f;
    logic [15:0] cdie_cbo_portids[$] ={'h0103, 'h0106, 'h0109, 'h010c};
    logic [15:0] cdie_ccf_pma_portid = 'h0138;
    logic [15:0] cdie_ccf_multicast_portid = 'h0198;

    // OPCODES
    logic [7:0] wp_req_opcode = 'h2f;
    logic [7:0] cbo_drain_msg_opcode = 'h79;
    logic [7:0] ncu_pcu_msg_opcode = 'h78;
    logic [7:0] cbo_drain_ack_opcode = 'hc0;
    logic [7:0] cmpd_opcode = 'h21;

    // ADDRESSES
    bit [3:0] svid_address = 4'h3;
    logic [15:0] die2soc_reset_flow_control_addr = 'h4d3c;
    logic [15:0] soc2die_reset_flow_control_addr = 'h2000;
    logic [15:0] svid_vr_req_cdie_addr = 'h4d58;
    logic [15:0] svid_vr_rsp_cdie_addr = 'h0014;
    logic [15:0] svid_vr_alert_cdie_addr = 'h0018;
    logic [3:0] svid_vccia_vr_address = 'h00;
    logic [15:0] svid_vr_alert_ack_addr = 'h4d5c;
    logic [15:0] wish_power_state_cdie2soc_addr = 'h4d48;
    logic [15:0] power_state_req_soc2cdie_addr = 'h0010;
    logic [15:0] power_state_rsp_cdie2soc_addr = 'h4d44;
    logic [15:0] resource_operating_mode_status_cdie2soc_addr = 'h4d4c;
    logic [15:0] resource_operating_mode_status_valid_cdie2soc_addr = 'h4d50;
    logic [15:0] diec_current_state_cdie2soc_addr = 'h4d64;
    logic [15:0] diec_status_update_valid_addr = 'h4d70;
    logic [15:0] resource_nde_cdie2soc_addr = 'h4d40;
    logic [15:0] resource_ltr_cdie2soc_addr = 'h4d54;
    logic [15:0] pcode2dcode_mailbox_remote_addr = 'h4208;
    logic [15:0] pcode2dcode_mailbox_local_addr = 'h5de4;
    logic [15:0] dmu_event_3_addr = 'h1c0c;
    logic [15:0] ncu_lock_control_status_addr = 'h5108;
    logic [15:0] slow_telem_18_addr = 'h95a0;
    logic [15:0] atom_turbo_ratio_limit_cores_addr = 'h44a8;
    logic [15:0] bigcore_turbo_ratio_limit_cores_addr = 'h44b8;
    logic [15:0] atom_turbo_ratio_limit_addr = 'h44b0;
    logic [15:0] bigcore_turbo_ratio_limit_addr = 'h44c0;
    logic [15:0] misc_power_management_addr = 'h4a90;
    logic [15:0] power_control_addr = 'h47f0;
    logic [15:0] pcie_bclk_freq_addr = 'h5f60;
    logic [15:0] cdie_therm_status_addr = 'h1cfc;
    logic [15:0] svid_ownership_semaphore_addr = 'h3000;

    logic [31:0] nde_data = 'h0;
    logic [31:0] ltr_data = 'h0;

    // DELAYS
    int delay_send_ack_sx_ps = 100;
    int delay_send_reset_warn_ack_ps = 100;
    int gpsb_qreqn_delay_in_ps = 1000000;
    int pmsb_qreqn_delay_in_ps = 1000000;
    int idi_qreqn_delay_in_ps = 20000;
    int gpsb_iso_req_delay_in_ps = 2000;
    int pmsb_iso_req_delay_in_ps = 2000;
    int idi_iso_req_delay_in_ps = 2000;
    int qreqn_retry_delay_in_ps = 50000;
    int clk_req_toggle_delay_in_ps = 1000;
    int crashlog_done_after_trigger_delay_in_ps = 50000;
    int pcode2decode_clear_runbusy_delay_in_ps = 10000;
    int dvfs_wp_ack_delay_in_ps = 10000;
    int power_state_response_delay_in_ps = 10000;
    int cdie_svid_get_reg_delay_in_ps = 10000;
    int cdie_svid_vr_alert_ack_delay_in_ps = 10000;
    int cdie_op_mode_status_valid_delay_in_ps = 1000;
    int cdie_current_status_valid_delay_in_ps = 10000;
    int cdie_local_half_bridge_reset_delay_in_ps = 20000;
    int cdie_sb_qreq_toggle_delay_in_ps = 1000000;
    int dc6_residency_delay_in_ps = 100000;
    int dc3_residency_delay_in_ps = 100000;
    logic [63:0] tsc_wakeup_time = 'hffff_ffff_ffff_ffff;
    int read_ratio_limit_delay_in_ps = 100;
    int read_misc_power_control_delay_in_ps = 100;
    int read_pcie_bclk_freq_delay_in_ps = 100;
    int svid_random_stimulus_delay_min_in_ps = 10_000_000;
    int svid_random_stimulus_delay_max_in_ps = 20_000_000;
    int svid_ownership_semaphore_polling_period_in_ps = 1000;


    function new(string name="cdie_clk_vc_config");
        super.new(name);
    endfunction

endclass
