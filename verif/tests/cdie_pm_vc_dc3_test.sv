// This test does a lot:
// Request for DC3.1 entry, go into DC3.1
// Request for DC3.2 entry, which requires going up to C1 to bring IDI up,
//    and then go back down to DC3.2 through DC2.2
// Wake from DC3.2 to DC1 via qactive; drop qactive and return to DC3.2
// Request for DC0 and go to DC0


class cdie_pm_vc_dc3_test extends cdie_pm_vc_dc_base_test;

    `uvm_component_utils(cdie_pm_vc_dc3_test)

    function new (string name="cdie_pm_vc_dc3_test", uvm_component parent=null);
        super.new (name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction

    function void connect();
        super.connect();
    endfunction

    virtual task test_content();
        idi_dielet_vif.QACTIVE = 0;
        gpsb_dielet_vif.QACTIVE = 0;
        pmsb_dielet_vif.QACTIVE = 0;
        do_cold_boot();
        delay_for_tb();

        request_dc_seq = new();
        request_dc_seq.randomize() with {
            state == DC3_1;
        };
        request_dc_seq.start(null);

        do_dc0_to_dc1();
        do_dc1_to_dc2_1();
        do_dc2_1_to_dc3_1();

        request_dc_seq = new();
        request_dc_seq.randomize() with {
            state == DC3_2;
        };
        request_dc_seq.start(null);

        do_dc3_1_to_dc2_1();
        do_dc2_1_to_dc1();

        do_dc1_to_dc2_2('b1);
        do_dc2_2_to_dc3_2('b1);

        delay_for_tb();

        idi_dielet_vif.QACTIVE = 'b1;
        do_dc3_2_to_dc2_2('b0);
        do_dc2_2_to_dc1('b0);
        idi_dielet_vif.QACTIVE = 'b0;
        do_dc1_to_dc2_2('b0);
        do_dc2_2_to_dc3_2('b0);

        request_dc_seq = new();
        request_dc_seq.randomize() with {
            state == DC0;
        };
        request_dc_seq.start(null);
        do_dc3_2_to_dc2_2('b1);
        do_dc2_2_to_dc1('b1);
        do_dc1_to_dc0();
    endtask

endclass


module cdie_pm_vc_dc3_test ();

    initial begin
        run_test("cdie_pm_vc_dc3_test");
    end

endmodule
