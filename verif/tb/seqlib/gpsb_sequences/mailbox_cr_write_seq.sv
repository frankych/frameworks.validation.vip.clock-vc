class mailbox_cr_write_seq extends base_gpsb_sequence;

    `uvm_object_utils(mailbox_cr_write_seq)

    function new(string name="");
        super.new(name);
    endfunction

    virtual task body();

        register_addr = new[2]('{cfg.pcode2dcode_mailbox_remote_addr[7:0], cfg.pcode2dcode_mailbox_remote_addr[15:8]});
        register_data = new[4]('{8'h00, 8'h00, 8'h00, 8'h10});
        opcode = iosfsbm_cm_uvm::OP_CRWR;

        send_regio_write();
    endtask
endclass