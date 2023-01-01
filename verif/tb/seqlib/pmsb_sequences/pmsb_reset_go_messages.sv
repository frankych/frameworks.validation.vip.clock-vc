class reset_send_go_s1_rw extends base_pmsb_sequence;
    
    `uvm_object_utils(reset_send_go_s1_rw)
    
    function new(string name="");
        super.new(name);
    endfunction
    
    task body();
        opcode = cdie_clk_vc_env_pkg::go_s1_rw;
        send_simple_txn();
    endtask
    
endclass

class reset_send_go_s1_temp extends base_pmsb_sequence;
    
    `uvm_object_utils(reset_send_go_s1_temp)
    
    function new(string name="");
        super.new(name);
    endfunction
    
    task body();        
        opcode = cdie_clk_vc_env_pkg::go_s1_temp;
        send_simple_txn();
    endtask
    
endclass

class reset_send_reset_warn extends base_pmsb_sequence;
    `uvm_object_utils(reset_send_go_s1_rw)
    
    function new(string name="");
        super.new(name);
    endfunction
    
    task body();
        opcode = cdie_clk_vc_env_pkg::reset_warn;
        send_simple_txn();
    endtask
endclass

class reset_send_go_s3 extends base_pmsb_sequence;
    `uvm_object_utils(reset_send_go_s3)
    
    function new(string name="");
        super.new(name);
    endfunction
    
    task body();
        opcode = cdie_clk_vc_env_pkg::go_s3;
        send_simple_txn();
    endtask
endclass

class reset_send_go_s4 extends base_pmsb_sequence;
    `uvm_object_utils(reset_send_go_s4)
    
    function new(string name="");
        super.new(name);
    endfunction
    
    task body();
        opcode = cdie_clk_vc_env_pkg::go_s4;
        send_simple_txn();
    endtask
endclass

class reset_send_go_s5 extends base_pmsb_sequence;
    `uvm_object_utils(reset_send_go_s5)
    
    function new(string name="");
        super.new(name);
    endfunction
    
    task body();
        opcode = cdie_clk_vc_env_pkg::go_s5;
        send_simple_txn();
    endtask
endclass
