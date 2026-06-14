`include "agrisense_defs.vh"

module tb_ipm_fsm;

    reg clk;
    reg rst_n;
    reg wake_timer;
    reg stress_event;
    reg [3:0] leaf_output;

    wire [1:0] state;
    wire domain2_pwr_en;
    wire domain3_pwr_en;
    wire sensor_en;
    wire decde_en;
    wire csa_en;
    wire dtree_en;
    wire comm_en;

    ipm_fsm dut (
        .clk(clk),
        .rst_n(rst_n),
        .wake_timer(wake_timer),
        .stress_event(stress_event),
        .leaf_output(leaf_output),
        .state(state),
        .domain2_pwr_en(domain2_pwr_en),
        .domain3_pwr_en(domain3_pwr_en),
        .sensor_en(sensor_en),
        .decde_en(decde_en),
        .csa_en(csa_en),
        .dtree_en(dtree_en),
        .comm_en(comm_en)
    );

    always #5 clk = ~clk;

    // Helper task to convert state to string for display
    function [63:0] state_str;
        input [1:0] st;
        begin
            case(st)
                `IPM_SLEEP:    state_str = "SLEEP   ";
                `IPM_MONITOR:  state_str = "MONITOR ";
                `IPM_WARNING:  state_str = "WARNING ";
                `IPM_CRITICAL: state_str = "CRITICAL";
                default:       state_str = "UNKNOWN ";
            endcase
        end
    endfunction

    initial begin
        clk = 0;
        rst_n = 0;
        wake_timer = 0;
        stress_event = 0;
        leaf_output = 4'b0100; // Initialize to low/warning severity so we don't immediately fall back to MONITOR

        $display("\n=== IPM FSM State Transition Test ===");
        
        #25 rst_n = 1;
        #10;
        $display("[%0t] Reset -> State: %s | D2:%b D3:%b | S:%b DEC:%b CSA:%b DT:%b COM:%b", 
                 $time, state_str(state), domain2_pwr_en, domain3_pwr_en, sensor_en, decde_en, csa_en, dtree_en, comm_en);

        // 1. SLEEP -> MONITOR
        @(posedge clk); #1; wake_timer = 1'b1;
        @(posedge clk); #1; wake_timer = 1'b0;
        #10;
        $display("[%0t] wake_timer -> State: %s | D2:%b D3:%b | S:%b DEC:%b CSA:%b DT:%b COM:%b", 
                 $time, state_str(state), domain2_pwr_en, domain3_pwr_en, sensor_en, decde_en, csa_en, dtree_en, comm_en);

        // 2. MONITOR -> WARNING
        @(posedge clk); #1; stress_event = 1'b1;
        @(posedge clk); #1; stress_event = 1'b0;
        #10;
        $display("[%0t] stress_event -> State: %s | D2:%b D3:%b | S:%b DEC:%b CSA:%b DT:%b COM:%b", 
                 $time, state_str(state), domain2_pwr_en, domain3_pwr_en, sensor_en, decde_en, csa_en, dtree_en, comm_en);

        // 3. WARNING -> CRITICAL
        @(posedge clk); #1; leaf_output = 4'b1100; // CRITICAL
        @(posedge clk); 
        #10;
        $display("[%0t] leaf_output=CRITICAL -> State: %s | D2:%b D3:%b | S:%b DEC:%b CSA:%b DT:%b COM:%b", 
                 $time, state_str(state), domain2_pwr_en, domain3_pwr_en, sensor_en, decde_en, csa_en, dtree_en, comm_en);

        // 4. CRITICAL -> WARNING
        @(posedge clk); #1; leaf_output = 4'b0100; // WARNING/LOW
        @(posedge clk); 
        #10;
        $display("[%0t] leaf_output=WARNING -> State: %s | D2:%b D3:%b | S:%b DEC:%b CSA:%b DT:%b COM:%b", 
                 $time, state_str(state), domain2_pwr_en, domain3_pwr_en, sensor_en, decde_en, csa_en, dtree_en, comm_en);

        // 5. WARNING -> MONITOR
        @(posedge clk); #1; leaf_output = 4'b0000; // NORMAL
        
        // Wait 1 cycle (10 ns) - state should still be WARNING due to hysteresis!
        @(posedge clk);
        #1;
        $display("[%0t] leaf_output=NORMAL (1st Cycle) -> State: %s (Expected: WARNING) | exit_ctr: %d", 
                 $time, state_str(state), dut.exit_ctr);
        if (state !== `IPM_WARNING) begin
            $display("ERROR: Left WARNING immediately!");
            $finish;
        end

        // Wait another cycle (10 ns) - state should now transition to MONITOR!
        @(posedge clk);
        #1;
        $display("[%0t] leaf_output=NORMAL (2nd Cycle) -> State: %s (Expected: MONITOR) | exit_ctr: %d", 
                 $time, state_str(state), dut.exit_ctr);
        if (state !== `IPM_MONITOR) begin
            $display("ERROR: Failed to transition to MONITOR after 2 cycles!");
            $finish;
        end

        #50;
        $display("\nIPM FSM Test Complete.\n");
        $finish;
    end

endmodule
