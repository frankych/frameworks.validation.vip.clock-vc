class gpsb_reg_write_sequence extends base_gpsb_sequence;

    `uvm_object_utils(gpsb_reg_write_sequence)

    rand logic [15:0] addr;
    rand logic [31:0] data;
    rand iosfsbm_cm_uvm::opcode_t write_opcode;

    constraint opcode_c {
        write_opcode inside {OP_CRWR, OP_MWR, OP_CFGWR};
    }

    function new(string name="");
        super.new(name);
    endfunction

    virtual task body();

        register_addr = new[2]('{addr[7:0], addr[15:8]});
        register_data = new[4]('{data[7:0], data[15:8], data[23:16], data[31:24]});
        opcode = write_opcode;

        send_regio_write();
    endtask
endclass