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
    input  wire [2:0] vote_threshold,

    output reg  [2:0] fusion_score,
    output reg        stress_event
);

    integer i;
    reg [2:0] count;

    // Combinatorial counting of active flags
    always @(*) begin
        count = 3'd0;
        for(i = 0; i < 5; i = i + 1) begin
            count = count + cross_flag_vector[i];
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
