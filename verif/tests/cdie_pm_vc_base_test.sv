`include "uvm_macros.svh"
import uvm_pkg::*;
import cdie_pm_vc_env_pkg::*;
import cdie_pm_vc_val_pkg::*;

`define CALL_TASK_WITH_TIMEOUT(task_name, time_to_wait) \
    fork begin \
        fork\
            begin \
                #(time_to_wait * 1us); \
                `uvm_fatal(get_type_name(), $sformatf("Timed out waiting for task %s", `"task_name`"))  \
            end \
            begin \
                `uvm_info(get_type_name(), $sformatf("Waiting for task %s", `"task_name`"), UVM_LOW) \
                task_name; \
                `uvm_info(get_type_name(), $sformatf("Done waiting for task %s", `"task_name`"), UVM_LOW) \
            end \
        join_any \
        disable fork; \
    end join

class cdie_pm_vc_base_test extends uvm_test;

    `uvm_component_utils(cdie_pm_vc_base_test)

    cdie_pm_vc_val_env val_env;

    function new (string name="cdie_pm_vc_base_test", uvm_component parent=null);
        super.new (name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        val_env = cdie_pm_vc_val_env::type_id::create("cdie_pm_vc_val_env",this);
        if ($test$plusargs("global_ep")) begin
            `uvm_info(get_type_name(), "Configuring VC endpoints to be global.", UVM_LOW)
            val_env.vc_env.cdie_pm_config.vc_ep_is_global = 'b1;
        end

    endfunction

    virtual task test_content();

    endtask

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        phase.raise_objection(this);
        test_content();
        phase.drop_objection(this);
    endtask

endclass

module cdie_pm_vc_base_test ();

    initial begin
        run_test("cdie_pm_vc_base_test");
    end

endmodule

