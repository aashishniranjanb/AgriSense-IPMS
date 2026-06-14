module normalization_unit(
    input  wire [18:0] weighted_sum_val,
    input  wire [3:0]  shift_factor,
    output wire [7:0]  stress_score
);

    wire [18:0] shifted_sum = weighted_sum_val >> shift_factor;
    
    // Saturation clamp to 255 to prevent overflow/wrap-around
    assign stress_score = (shifted_sum > 19'd255) ? 8'd255 : shifted_sum[7:0];

endmodule
