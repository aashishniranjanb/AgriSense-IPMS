`include "agrisense_defs.vh"

module tb_ipm_fsm;

    reg clk;
    reg rst_n;
    reg wake_timer;
    reg stress_event;
    reg [1:0] leaf_output;

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
        leaf_output = 2'b00;

        $display("\n=== IPM FSM State Transition Test ===");
        
        #25 rst_n = 1;
        #10;
        $display("[%0t] Reset -> State: %s | D2:%b D3:%b | S:%b DEC:%b CSA:%b DT:%b COM:%b", 
                 $time, state_str(state), domain2_pwr_en, domain3_pwr_en, sensor_en, decde_en, csa_en, dtree_en, comm_en);

        // 1. SLEEP -> MONITOR
        @(posedge clk); wake_timer = 1'b1;
        @(posedge clk); wake_timer = 1'b0;
        #10;
        $display("[%0t] wake_timer -> State: %s | D2:%b D3:%b | S:%b DEC:%b CSA:%b DT:%b COM:%b", 
                 $time, state_str(state), domain2_pwr_en, domain3_pwr_en, sensor_en, decde_en, csa_en, dtree_en, comm_en);

        // 2. MONITOR -> WARNING
        @(posedge clk); stress_event = 1'b1;
        @(posedge clk); stress_event = 1'b0;
        #10;
        $display("[%0t] stress_event -> State: %s | D2:%b D3:%b | S:%b DEC:%b CSA:%b DT:%b COM:%b", 
                 $time, state_str(state), domain2_pwr_en, domain3_pwr_en, sensor_en, decde_en, csa_en, dtree_en, comm_en);

        // 3. WARNING -> CRITICAL
        @(posedge clk); leaf_output = 2'b10; // CRITICAL
        @(posedge clk); 
        #10;
        $display("[%0t] leaf_output=CRITICAL -> State: %s | D2:%b D3:%b | S:%b DEC:%b CSA:%b DT:%b COM:%b", 
                 $time, state_str(state), domain2_pwr_en, domain3_pwr_en, sensor_en, decde_en, csa_en, dtree_en, comm_en);

        // 4. CRITICAL -> WARNING
        @(posedge clk); leaf_output = 2'b01; // WARNING
        @(posedge clk); 
        #10;
        $display("[%0t] leaf_output=WARNING -> State: %s | D2:%b D3:%b | S:%b DEC:%b CSA:%b DT:%b COM:%b", 
                 $time, state_str(state), domain2_pwr_en, domain3_pwr_en, sensor_en, decde_en, csa_en, dtree_en, comm_en);

        // 5. WARNING -> MONITOR
        @(posedge clk); leaf_output = 2'b00; // NORMAL
        @(posedge clk); 
        #10;
        $display("[%0t] leaf_output=NORMAL -> State: %s | D2:%b D3:%b | S:%b DEC:%b CSA:%b DT:%b COM:%b", 
                 $time, state_str(state), domain2_pwr_en, domain3_pwr_en, sensor_en, decde_en, csa_en, dtree_en, comm_en);

        #50;
        $display("\nIPM FSM Test Complete.\n");
        $finish;
    end

endmodule
