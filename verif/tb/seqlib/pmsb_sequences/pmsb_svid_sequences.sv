class svid_vr_response_base extends base_pmsb_sequence;
    `uvm_object_utils(svid_vr_response_base)

    bit transmit_complete = 1'b0;
    bit error = 1'b0;
    bit vr_settled = 1'b0;
    bit therm_alert = 1'b0;
    bit iccmax_alert = 1'b0;
    bit vid_dac_high = 1'b0;
    bit read_status_2 = 1'b0;

    function new(string name="");
        super.new(name);
    endfunction

    task body();
        logic [3:0] rail_id = cfg.svid_address;
        logic [7:0] byte_0 = {rail_id, 2'b00, error, transmit_complete};
        logic [7:0] byte_1 = {2'b00, read_status_2, 1'b0, vid_dac_high, iccmax_alert, therm_alert, vr_settled};
        register_addr = new[2]('{cfg.svid_vr_rsp_cdie_addr[7:0], cfg.svid_vr_rsp_cdie_addr[15:8]});
        register_data = new[4]('{byte_0,  byte_1, 8'h00, 8'h00});
        opcode = iosfsbm_cm_uvm::OP_CRWR;

        send_regio_txn();
    endtask
endclass

class svid_send_transmit_complete extends svid_vr_response_base;

    function new(string name="");
        super.new(name);
        transmit_complete = 1'b1;
    endfunction
endclass

class svid_send_vr_settled extends svid_vr_response_base;

    function new(string name="");
        super.new(name);
        vr_settled = 1'b1;
    endfunction
endclass

class svid_send_vr_alert extends base_pmsb_sequence;

    `uvm_object_utils(svid_send_vr_alert)

    function new(string name="");
        super.new(name);
    endfunction

    task body();
        bit alert = 1'b1;
        logic [7:0] byte_0 = {7'h00, alert};
        register_addr = new[2]('{cfg.svid_vr_alert_cdie_addr[7:0], cfg.svid_vr_alert_cdie_addr[15:8]});
        register_data = new[4]('{byte_0,  8'h00, 8'h00, 8'h00});
        opcode = iosfsbm_cm_uvm::OP_CRWR;

        send_regio_txn();
    endtask
endclass
