class config_file_writer extends uvm_object;
    `uvm_object_utils(config_file_writer)

    int logfile_id;

    function new (string name = "");
        super.new(name);
    endfunction

    function void init_file(string filename);
        logfile_id = $fopen(filename, "a+");
    endfunction

    function void close_file();
        $fclose(logfile_id);
    endfunction
    
    function void write_config_to_file_raw(cdie_clk_vc_config config_obj);
        $fwrite(logfile_id, $sformatf("%p", config_obj));
    endfunction
endclass
