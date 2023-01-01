import "DPI-C" context task cdie_send_power_info();

class cdie_send_power_info_seq extends uvm_sequence;

    `uvm_object_utils(cdie_send_power_info_seq)

    function new(string name="cdie_send_power_info_seq");
        super.new(name);
    endfunction

    virtual task body();
        fork
            cdie_send_power_info();
        join_none
    endtask

endclass