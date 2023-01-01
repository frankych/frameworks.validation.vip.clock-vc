class cdie_pm_vc_sb_test extends cdie_pm_vc_base_test;

    `uvm_component_utils(cdie_pm_vc_sb_test)
    virtual sideband_interface agent_sideband_interface;
    virtual sideband_interface fabric_sideband_interface;

    function new (string name="cdie_pm_vc_sb_test", uvm_component parent=null);
        super.new (name, parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db #(virtual sideband_interface)::get(null, "*", "gpsb_agent_sideband_interface", agent_sideband_interface))
            `uvm_fatal(get_type_name(), "Unable to find the agent_sideband_interface virtual interface in the uvm_config_db")
        if(!uvm_config_db #(virtual sideband_interface)::get(null, "*", "gpsb_fabric_sideband_interface", fabric_sideband_interface))
            `uvm_fatal(get_type_name(), "Unable to find the fabric_sideband_interface virtual interface in the uvm_config_db")
    endfunction

    function void connect();
        super.connect();
    endfunction

    virtual task test_content();        
        #10ns;
        agent_sideband_interface.side_rst_b = 1'b1;
        #1ns;
        fabric_sideband_interface.side_rst_b = 1'b1;
        `uvm_info(get_type_name(), "Basic DOA test running successfully.", UVM_LOW);
    endtask

endclass


module cdie_pm_vc_sb_test ();

    initial begin
        run_test("cdie_pm_vc_sb_test");
    end

endmodule
