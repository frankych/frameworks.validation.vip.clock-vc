typedef string config_array [string];

typedef enum logic [7:0]{
    DC0 = 'h0,
    DC1 = 'h10,
    DC2_1 = 'h21,
    DC2_2 = 'h22,
    DC3_1 = 'h31,
    DC3_2 = 'h32,
    DC6 = 'h60
} cdie_cstate_t;

typedef enum logic [7:0]{
    core_on = 'h12,
    core_off_c6sram_in_retention = 'h11,
    core_off = 'h10
} core_op_mode_t;

typedef enum logic [7:0]{
    ccf_on = 'h20,
    ccf_cache_in_retention = 'h21,
    ccf_off = 'h22
} ccf_op_mode_t;

typedef enum logic [7:0]{
    fabric_on = 'h31,
    fabric_off = 'h30
} fabric_op_mode_t;

typedef enum logic [7:0]{
    go_s0 = 'hC0,
    go_s1_temp = 'hC1,
    go_s1_final = 'hC2,
    go_s1_rw = 'hC3,
    go_s3 = 'hC4,
    go_s4 = 'hC5,
    go_s5 = 'hC6,
    ack_sx = 'hC7,
    nack_sx = 'hCF,
    reset_warn = 'hAE,
    reset_warn_ack = 'hAF
} boot_reset_opcodes_t;

parameter PUNIT_GPSB_PORTID = 'had;
parameter DMU_GPSB_PORTID = 'h46;
parameter PUNIT_PMSB_PORTID = 'hf6;
parameter DMU_PMSB_PORTID = 'h01;
parameter SB_VC_PACKET_WIDTH = 8;
parameter NUM_BYTES_IN_DWORD = 4;
parameter NUM_BYTES_IN_DOUBLE_DWORD = 8;
parameter NUM_BITS_IN_DWORD = 32;
parameter SET_VID_FAST = 1;
parameter SET_VID_SLOW = 2;
parameter SET_VID_DECAY = 3;
parameter GET_REG = 7;
