module weighted_sum(
    input wire [7:0] sensor_value,
    input wire [7:0] weight,
    output wire [15:0] product
);
    assign product = sensor_value * weight;
endmodule
