class cdie_pm_vc_cr_access_test extends cdie_pm_vc_cold_boot_test;

    `uvm_component_utils(cdie_pm_vc_cr_access_test)

    logic [63:0] completion_data;

    function new (string name="cdie_pm_vc_cr_access_test", uvm_component parent=null);
        super.new (name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction

    function void connect();
        super.connect();
        val_env.vc_env.load_gpsb_cr_data('hc7, 'h3450, 'hbeefbeef);
        val_env.vc_env.gpsb_to_py_port.set_dest_portid('ha0);
    endfunction

    task delay_for_tb();
        #5ns;
    endtask

    virtual task test_content();
        super.test_content();


        test_gpsb_cr_access(iosfsbm_cm_uvm::OP_CRRD, iosfsbm_cm_uvm::OP_CRWR, 'hdea0);
        test_gpsb_cr_access(iosfsbm_cm_uvm::OP_CRRD, iosfsbm_cm_uvm::OP_CRWR, 'hdeb0);
        test_pmsb_cr_access(iosfsbm_cm_uvm::OP_MRD, iosfsbm_cm_uvm::OP_MWR, 'hdec0);
        test_pmsb_cr_access(iosfsbm_cm_uvm::OP_MRD, iosfsbm_cm_uvm::OP_MWR, 'hded0);
        test_gpsb_cr_access(iosfsbm_cm_uvm::OP_CFGRD, iosfsbm_cm_uvm::OP_CFGWR, 'h0e90);
        test_pmsb_cr_access(iosfsbm_cm_uvm::OP_CFGRD, iosfsbm_cm_uvm::OP_CFGWR, 'h0e80);
        test_64_bit_load();
        test_gpsb_cr_default('h0103, 'h6800);
    endtask
    
    task test_gpsb_cr_default(logic [15:0] portid, logic [15:0] addr_of_reg_with_non_random_default_value);
        gpsb_reg_read_sequence reg_read_sequence;
        reg_read_sequence = new();
        reg_read_sequence.randomize() with {read_opcode == iosfsbm_cm_uvm::OP_CRRD; addr == addr_of_reg_with_non_random_default_value;};
        reg_read_sequence.dest_id = portid;
        reg_read_sequence.start(null);

        `CALL_TASK_WITH_TIMEOUT(wait_for_completion(gpsb_fifo), 5)
        if (completion_data != 'h1000208)
            `uvm_error(get_type_name(), $sformatf("Expected default data from read to address %h, got data of %h", addr_of_reg_with_non_random_default_value, completion_data))
    endtask

    task test_gpsb_cr_access(iosfsbm_cm_uvm::opcode_t rd_opcode, iosfsbm_cm_uvm::opcode_t wr_opcode, logic [15:0] addr);
        read_gpsb_register(addr, rd_opcode);
        if (completion_data == 'h0)
            `uvm_error(get_type_name(), $sformatf("Expected random data from read to address %h, got data of 0x0", addr))

        delay_for_tb();
        if(rd_opcode == iosfsbm_cm_uvm::OP_CRRD || rd_opcode == iosfsbm_cm_uvm::OP_CFGRD)
            val_env.vc_env.load_gpsb_cr_data('hc7, addr, 'hacedcafe);
        else
            val_env.vc_env.load_gpsb_mem_data(addr, 'hacedcafe);
        read_gpsb_register(addr, rd_opcode);
        if (completion_data != 'hacedcafe)
            `uvm_error(get_type_name(), $sformatf("Expected data of %h from read to address %h, got data of %h", 'hacedcafe, addr, completion_data))

        delay_for_tb();
        write_gpsb_register(addr, 'hbeeffeed, wr_opcode);
        read_gpsb_register(addr, rd_opcode);
        if (completion_data != 'hbeeffeed)
            `uvm_error(get_type_name(), $sformatf("Expected data of %h data from read to address %h, got data of %h", 'hbeeffeed, addr, completion_data))
    endtask


    task test_pmsb_cr_access(iosfsbm_cm_uvm::opcode_t rd_opcode, iosfsbm_cm_uvm::opcode_t wr_opcode, logic [15:0] addr);
        read_pmsb_register(addr, rd_opcode);
        if (completion_data == 'h0)
            `uvm_error(get_type_name(), $sformatf("Expected random data from read to address %h, got data of 0x0", addr))

        delay_for_tb();
        if(rd_opcode == iosfsbm_cm_uvm::OP_CRRD || rd_opcode == iosfsbm_cm_uvm::OP_CFGRD)
            val_env.vc_env.load_pmsb_cr_data('h30, addr, 'hacedcafe);
        else
            val_env.vc_env.load_pmsb_mem_data(addr, 'hacedcafe);
        read_pmsb_register(addr, rd_opcode);
        if (completion_data != 'hacedcafe)
            `uvm_error(get_type_name(), $sformatf("Expected data of %h from read to address %h, got data of %h", 'hacedcafe, addr, completion_data))

        delay_for_tb();
        write_pmsb_register(addr, 'hbeeffeed, wr_opcode);
        read_pmsb_register(addr, rd_opcode);
        if (completion_data != 'hbeeffeed)
            `uvm_error(get_type_name(), $sformatf("Expected data of %h data from read to address %h, got data of %h", 'hbeeffeed, addr, completion_data))
    endtask


    task wait_for_completion(uvm_tlm_analysis_fifo #(iosfsbm_cm_uvm::xaction) fifo);
        logic [63:0] data;
        iosfsbm_cm_uvm::xaction txn;
        iosfsbm_cm_uvm::comp_xaction comp_txn;
        do begin fifo.get(txn); end
        while(!($cast(comp_txn, txn) && comp_txn.opcode == iosfsbm_cm_uvm::OP_CMPD));

        completion_data = {comp_txn.data[3], comp_txn.data[2], comp_txn.data[1], comp_txn.data[0]};
        if(comp_txn.data.size() == 4) begin
            completion_data[63:32] = 'h0;
        end else begin
            completion_data[63:32] = {comp_txn.data[7], comp_txn.data[6], comp_txn.data[5], comp_txn.data[4]};
        end
    endtask

    task read_gpsb_register(logic [15:0] read_addr, iosfsbm_cm_uvm::opcode_t rd_opcode);
        gpsb_reg_read_sequence reg_read_sequence;
        reg_read_sequence = new();
        reg_read_sequence.randomize() with {read_opcode == rd_opcode; addr == read_addr;};
        reg_read_sequence.start(null);

        `CALL_TASK_WITH_TIMEOUT(wait_for_completion(gpsb_fifo), 5)

    endtask

    task write_gpsb_register(logic [15:0] write_addr, logic [31:0] write_data, iosfsbm_cm_uvm::opcode_t wr_opcode);
        gpsb_reg_write_sequence reg_write_sequence;
        reg_write_sequence = new();
        reg_write_sequence.randomize() with {write_opcode == wr_opcode; addr == write_addr; data == write_data;};
        reg_write_sequence.start(null);

    endtask

    task read_pmsb_register(logic [15:0] read_addr, iosfsbm_cm_uvm::opcode_t rd_opcode);
        pmsb_reg_read_sequence reg_read_sequence;
        reg_read_sequence = new();
        reg_read_sequence.randomize() with {read_opcode == rd_opcode; addr == read_addr;};
        reg_read_sequence.start(null);

        `CALL_TASK_WITH_TIMEOUT(wait_for_completion(pmsb_fifo), 5)

    endtask

    task write_pmsb_register(logic [15:0] write_addr, logic [31:0] write_data, iosfsbm_cm_uvm::opcode_t wr_opcode);
        pmsb_reg_write_sequence reg_write_sequence;
        reg_write_sequence = new();
        reg_write_sequence.randomize() with {write_opcode == wr_opcode; addr == write_addr; data == write_data;};
        reg_write_sequence.start(null);

    endtask

    task test_64_bit_load();
        gpsb_reg_read_sequence reg_read_sequence;
        val_env.vc_env.load_gpsb_cr_data('hc7, 'h6000, 'h1234_5678_9abc_def0);

        reg_read_sequence = new();
        reg_read_sequence.randomize() with {read_opcode == iosfsbm_cm_uvm::OP_CRRD; addr == 'h6000; read_sbe == 'hf;};
        reg_read_sequence.start(null);
        `CALL_TASK_WITH_TIMEOUT(wait_for_completion(gpsb_fifo), 5)
        if (completion_data != 'h1234_5678_9abc_def0)
            `uvm_error(get_type_name(), $sformatf("64 bit read did not return expected data, got %h for data", completion_data));

    endtask

endclass



module cdie_pm_vc_cr_access_test ();

    initial begin
        run_test("cdie_pm_vc_cr_access_test");
    end

endmodule
