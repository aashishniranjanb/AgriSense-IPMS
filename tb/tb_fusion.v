module tb_fusion;

    reg        clk;
    reg        rst_n;
    reg  [4:0] cross_flag_vector;
    reg  [4:0] trend_direction_vector;
    reg  [9:0] fusion_pattern;
    reg  [2:0] vote_threshold;
    reg  [7:0] window_size;

    wire [2:0] fusion_score;
    wire       stress_event;

    fusion_unit dut (
        .clk(clk),
        .rst_n(rst_n),
        .cross_flag_vector(cross_flag_vector),
        .trend_direction_vector(trend_direction_vector),
        .fusion_pattern(fusion_pattern),
        .vote_threshold(vote_threshold),
        .window_size(window_size),
        .fusion_score(fusion_score),
        .stress_event(stress_event)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst_n = 0;
        cross_flag_vector = 5'b00000;
        trend_direction_vector = 5'b00000;
        fusion_pattern = 10'b0000000000; // Don't Care (direction-agnostic)
        vote_threshold = 3'd2; 
        window_size = 8'd4; // sliding window size of 4 cycles

        #25 rst_n = 1;

        $display("\n=== Fusion Unit v1.0 Temporal correlation tests ===");

        // Step 1: Drive channel 0 crossover at Cycle N
        @(negedge clk);
        cross_flag_vector = 5'b00001; 
        $display("[Cycle N] Triggering crossover on Channel 0");
        
        @(posedge clk); #1;
        $display("  [Cycle N+1 Edge] recent_cross: %b, window_ctr[0]: %d", dut.recent_cross, dut.window_ctr[0]);

        // Step 2: Clear crossovers at Cycle N+1
        @(negedge clk);
        cross_flag_vector = 5'b00000;
        $display("[Cycle N+1] Crossovers cleared");
        
        @(posedge clk); #1;
        $display("  [Cycle N+2 Edge] recent_cross: %b, window_ctr[0]: %d", dut.recent_cross, dut.window_ctr[0]);

        // Step 3: Drive channel 1 crossover at Cycle N+2 (2 cycles later, within window size 4)
        @(negedge clk);
        cross_flag_vector = 5'b00010;
        $display("[Cycle N+2] Triggering crossover on Channel 1 (Lagged)");
        
        @(posedge clk); #1;
        $display("  [Cycle N+3 Edge] recent_cross: %b, window_ctr[0]: %d, window_ctr[1]: %d, score: %d, event: %b", 
                 dut.recent_cross, dut.window_ctr[0], dut.window_ctr[1], fusion_score, stress_event);

        // Step 4: Clear crossovers at Cycle N+3
        @(negedge clk);
        cross_flag_vector = 5'b00000;
        
        @(posedge clk); #1;
        $display("  [Cycle N+4 Edge] recent_cross: %b, window_ctr[0]: %d, window_ctr[1]: %d, score: %d, event: %b", 
                 dut.recent_cross, dut.window_ctr[0], dut.window_ctr[1], fusion_score, stress_event);

        if (stress_event !== 1'b1) begin
            $display("ERROR: Failed to detect lagged correlated crossover event!");
        end else begin
            $display("SUCCESS: Temporal correlation voting verified!");
        end

        #20;
        $finish;
    end

endmodule
