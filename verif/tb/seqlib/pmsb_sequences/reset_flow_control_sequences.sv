class soc2die_reset_flow_control_base extends base_pmsb_sequence;

    `uvm_object_utils(soc2die_reset_flow_control_base)

    bit die_config_cycle_done = 1'b0;
    bit gp_sbb_ready = 1'b0;
    bit pm_sbb_ready = 1'b0;
    bit core_wake_ack = 1'b0;
    bit bios_reset_complete = 1'b0;

    function new(string name="");
        super.new(name);
    endfunction

    virtual task body();
        
        
        logic [7:0] lsbyte_soc2die_reset_flow_control = {3'h0, bios_reset_complete, core_wake_ack, die_config_cycle_done, gp_sbb_ready, pm_sbb_ready};
        register_addr = new[2]('{cfg.soc2die_reset_flow_control_addr[7:0], cfg.soc2die_reset_flow_control_addr[15:8]});        
        register_data = new[4]('{lsbyte_soc2die_reset_flow_control, 8'h00, 8'h00, 8'h00});
        opcode = iosfsbm_cm_uvm::OP_CRWR;
        
        send_regio_txn();
    endtask
endclass

class soc2die_send_pm_sbb_ready extends soc2die_reset_flow_control_base;

    `uvm_object_utils(soc2die_send_pm_sbb_ready)

    function new(string name="");
        super.new(name);
        pm_sbb_ready = 1'b1;
        gp_sbb_ready = 1'b1;
    endfunction
endclass

class soc2die_send_config_cycle_done extends soc2die_send_pm_sbb_ready;

    `uvm_object_utils(soc2die_send_config_cycle_done)

    function new(string name="");
        super.new(name);
        die_config_cycle_done = 1'b1;
        gp_sbb_ready = 1'b1;
        pm_sbb_ready = 1'b1;
    endfunction
endclass

class soc2die_release_config_cycle_done extends soc2die_send_config_cycle_done;

    `uvm_object_utils(soc2die_release_config_cycle_done)

    function new(string name="");
        super.new(name);
        die_config_cycle_done = 1'b0;
    endfunction
endclass

class soc2die_send_core_wake_ack extends soc2die_send_pm_sbb_ready;

    `uvm_object_utils(soc2die_send_core_wake_ack)

    function new(string name="");
        super.new(name);
        core_wake_ack = 1'b1;
    endfunction
endclass

class soc2die_send_bios_complete extends soc2die_send_core_wake_ack;

    `uvm_object_utils(soc2die_send_core_wake_ack)

    function new(string name="");
        super.new(name);
        bios_reset_complete = 1'b1;
    endfunction
endclass