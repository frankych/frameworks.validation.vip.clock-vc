import "DPI-C" context task cdie_send_svid_seq(int enable_alert, int command, int payload);

typedef enum logic [4:0] {
    SETVID_FAST = 'h1,
    SETVID_SLOW = 'h2,
    SETVID_DECAY = 'h3,
    SET_PS = 'h4
} svid_commands_t;

class cdie_send_user_svid_seq extends uvm_sequence;
    
    rand bit enable_alert;
    rand bit [4:0] command;
    rand bit [7:0] payload;

    virtual task body();
        cdie_send_svid_seq(enable_alert, command, payload);
    endtask

endclass
