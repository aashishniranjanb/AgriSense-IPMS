module crossover_detector (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        sample_valid,
    input  wire [15:0] fast_ema,
    input  wire [15:0] slow_ema,
    output reg         cross_flag,
    output reg         trend_direction
);

    reg prev_relation;
    reg initialized;
    
    // True if Fast > Slow
    wire current_relation = (fast_ema > slow_ema);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cross_flag      <= 1'b0;
            trend_direction <= 1'b0;
            prev_relation   <= 1'b0;
            initialized     <= 1'b0;
        end else begin
            // cross_flag is meant to pulse for exactly one cycle when crossover is detected
            cross_flag <= 1'b0; 

            if (sample_valid) begin
                if (!initialized) begin
                    prev_relation <= current_relation;
                    initialized   <= 1'b1;
                end else begin
                    // Crossover detected
                    if (current_relation != prev_relation) begin
                        cross_flag      <= 1'b1;
                        trend_direction <= current_relation; // 1 = Rising trend, 0 = Falling trend
                    end
                    prev_relation <= current_relation;
                end
            end
        end
    end

endmodule
