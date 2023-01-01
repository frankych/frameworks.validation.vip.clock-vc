interface cdie_pm_vc_if;

    logic early_boot_pd_on;
    logic cold_boot_trigger;
    logic warm_boot_trigger;
    wire Tscsync;
    wire TSCDownLoadTrigger = 'b0;

    wire crashlog_trigger;
    wire crashlog_done;

    wire thermtripout; // not driven by VC except initialization
    wire caterr_indication; // not driven by VC except initialization
    wire prochot_indication;

    // DVFS
    wire go_prep_unprep;
    wire go_prep_unprep_ack;
    wire go_incgb_decgb_req;
    wire go_incgb_decgb_ack;

    wire bclk_clk_req = 1;
    wire xtal_clk_req = 1;
    wire cro_clk_req = 1;

    wire bclk_clk_ack;
    wire xtal_clk_ack;
    wire cro_clk_ack;

    logic local_half_bridge_rst_b_async = 'b0;
    logic local_half_bridge_rst_b_sync = 'b0;

    logic local_half_bridge_clk;
    
    logic [7:0] cdie_current_state = 'h0;

    `include "pydoh_if_api.sv"

    `create_pydoh_signal_monitor(early_boot_pd_on)
    `create_pydoh_signal_monitor(cold_boot_trigger)
    `create_pydoh_signal_monitor(warm_boot_trigger)
    `create_pydoh_signal_monitor(crashlog_trigger)
    `create_pydoh_signal_monitor(go_prep_unprep)
    `create_pydoh_signal_monitor(go_incgb_decgb_req)
    
    `create_pydoh_signal_monitor(bclk_clk_ack)
    `create_pydoh_signal_monitor(xtal_clk_ack)
    `create_pydoh_signal_monitor(cro_clk_ack)

    always @(posedge local_half_bridge_clk) begin
        local_half_bridge_rst_b_sync = local_half_bridge_rst_b_async;
    end

endinterface
