interface cdie_pm_vc_dielet_pm_if;

    logic iso_req_b;
    logic iso_ack_b;

    logic QREQn;
    logic QACCEPTn;
    logic QDENY;
    logic QACTIVE;
    
    logic coherent_traffic_req;
    logic coherent_traffic_ack;

    `include "pydoh_if_api.sv"

    `create_pydoh_signal_monitor(iso_ack_b);
    `create_pydoh_signal_monitor(QACCEPTn);
    `create_pydoh_signal_monitor(QDENY);
    `create_pydoh_signal_monitor(QACTIVE);
    
    `create_pydoh_signal_monitor(coherent_traffic_ack)

endinterface
