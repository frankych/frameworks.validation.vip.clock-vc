class cdie_pm_vc_dc6_test extends cdie_pm_vc_dc_base_test;

    `uvm_component_utils(cdie_pm_vc_dc6_test)

    function new (string name="cdie_pm_vc_dc6_test", uvm_component parent=null);
        super.new (name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction

    function void connect();
        super.connect();
    endfunction

    virtual task test_content();
        do_cold_boot();
        delay_for_tb();

        request_dc_seq = new();
        request_dc_seq.randomize() with {
            state == DC6;
        };
        request_dc_seq.start(null);

        do_dc0_to_dc1();
        do_dc1_to_dc2_2('b1);
        do_dc2_2_to_dc6();

        delay_for_tb();
        request_dc_seq = new();
        request_dc_seq.randomize() with {
            state == DC0;
        };
        request_dc_seq.start(null);

        #20ns;

        if(pmsb_dielet_vif.iso_req_b == 'b1)
            `uvm_error(get_type_name(), "DC6 exit began without a QACTIVE indication")

        pmsb_dielet_vif.QACTIVE = 'b1;
        do_dc6_to_dc2_2();
        do_dc2_2_to_dc1('b1);
        do_dc1_to_dc0();
    endtask

endclass


module cdie_pm_vc_dc6_test ();

    initial begin
        run_test("cdie_pm_vc_dc6_test");
    end

endmodule
