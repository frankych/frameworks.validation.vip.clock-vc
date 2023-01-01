class cdie_pm_vc_doa_test extends cdie_pm_vc_base_test;

    `uvm_component_utils(cdie_pm_vc_doa_test)

    function new (string name="cdie_pm_vc_doa_test", uvm_component parent=null);
        super.new (name, parent);
    endfunction

    function void connect();
        super.connect();
    endfunction

    virtual task test_content();
        #10;
        `uvm_info(get_type_name(), "Basic DOA test running successfully.", UVM_LOW)
    endtask

endclass



module cdie_pm_vc_doa_test ();

    initial begin
        run_test("cdie_pm_vc_doa_test");
    end

endmodule
