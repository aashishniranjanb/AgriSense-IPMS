// Tag: fusion_v0_1
//
// TODO:
// Add sliding window correlation
// Add trend-direction filtering
// Add temporal voting logic

module fusion_unit(
    input  wire       clk,
    input  wire       rst_n,

    input  wire [4:0] cross_flag_vector,
    input  wire [4:0] trend_direction_vector,
    input  wire [9:0] fusion_pattern,
    input  wire [2:0] vote_threshold,
    /* verilator lint_off UNUSEDSIGNAL */
    input  wire [7:0] window_size,
    /* verilator lint_on UNUSEDSIGNAL */

    output reg  [2:0] fusion_score,
    output reg        stress_event
);

    reg [3:0] window_ctr [0:4];
    reg [4:0] recent_cross;
    reg [4:0] recent_direction;

    integer j;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            recent_cross <= 5'b0;
            recent_direction <= 5'b0;
            for (j = 0; j < 5; j = j + 1) begin
                window_ctr[j] <= 4'd0;
            end
        end else begin
            for (j = 0; j < 5; j = j + 1) begin
                if (cross_flag_vector[j]) begin
                    recent_cross[j] <= 1'b1;
                    window_ctr[j]   <= window_size[3:0];
                    recent_direction[j] <= trend_direction_vector[j];
                end else if (window_ctr[j] > 4'd0) begin
                    window_ctr[j] <= window_ctr[j] - 4'd1;
                    if (window_ctr[j] == 4'd1) begin
                        recent_cross[j] <= 1'b0;
                        recent_direction[j] <= 1'b0;
                    end
                end else begin
                    recent_cross[j] <= 1'b0;
                    recent_direction[j] <= 1'b0;
                end
            end
        end
    end

    reg [4:0] qualified_cross;
    integer k;
    always @(*) begin
        for (k = 0; k < 5; k = k + 1) begin
            if (recent_cross[k]) begin
                case (fusion_pattern[2*k +: 2])
                    2'b00: qualified_cross[k] = 1'b1; // Don't Care
                    2'b01: qualified_cross[k] = recent_direction[k]; // Rising
                    2'b10: qualified_cross[k] = !recent_direction[k]; // Falling
                    2'b11: qualified_cross[k] = 1'b0; // Excluded
                    default: qualified_cross[k] = 1'b0;
                endcase
            end else begin
                qualified_cross[k] = 1'b0;
            end
        end
    end

    integer i;
    reg [2:0] count;

    // Combinatorial counting of active qualified flags
    always @(*) begin
        count = 3'd0;
        for(i = 0; i < 5; i = i + 1) begin
            count = count + qualified_cross[i];
        end
    end

    // Sequential registered outputs
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            fusion_score <= 3'd0;
            stress_event <= 1'b0;
        end
        else begin
            fusion_score <= count;

            if(count >= vote_threshold)
                stress_event <= 1'b1;
            else
                stress_event <= 1'b0;
        end
    end

endmodule
