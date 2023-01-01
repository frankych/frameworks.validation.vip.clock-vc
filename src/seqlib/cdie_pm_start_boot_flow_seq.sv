import "DPI-C" context task start_cdie_cold_boot_sequence();

class cdie_pm_start_boot_flow_seq extends uvm_sequence;

    `uvm_object_utils(cdie_pm_start_boot_flow_seq)

    function new(string name="");
        super.new(name);
    endfunction

    virtual task body();
        uvm_event pydoh_initialized;
        if(!uvm_config_db#(uvm_event)::get(null, "", "pydoh_initialization_event", pydoh_initialized))
            `uvm_fatal(get_type_name(), "Pydoh initialization event was never registered to config_db");

        pydoh_initialized.wait_on();
        fork
            start_cdie_cold_boot_sequence();
        join_none
    endtask
endclass
