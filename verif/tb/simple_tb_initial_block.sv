initial begin
    string fsdbFile;
    if($test$plusargs("fsdb"))
    begin
        $fsdbDumpfile("test.fsdb");
        $fsdbDumpvars;  // Default is dump everything.
        $fsdbDumpon;
    end
end


initial begin
    $display("Note: START OF TEST");
    $display("SIMSTAT:==============  Begin Test  ==================");
    fork
        begin
            #50us; $display("SIMSTAT:==============  Test @ 1ms ==================");
        end
    join_any
    disable fork;

    $display("Note: (final) $finish at simulation time: ", $time);
    $fflush(); //flush open files
    $finish;
end 
