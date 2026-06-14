module decde_channel #(
    parameter SENSOR_ID = 3'd0
)(
    input  wire       clk,
    input  wire       rst_n,

    input  wire       sample_valid,
    input  wire [7:0] sensor_sample,
    input  wire [2:0] shift_factor,

    output wire       cross_flag,
    output wire       trend_direction,
    output wire [2:0] sensor_id_out
);

    assign sensor_id_out = SENSOR_ID;

    wire [2:0] k_fast = shift_factor;
    wire [2:0] k_slow = shift_factor + 3'd2;

    wire [15:0] fast_ema;
    wire [15:0] slow_ema;

    ema_filter fast_ema_inst (
        .clk           (clk),
        .rst_n         (rst_n),
        .sample_valid  (sample_valid),
        .sample        (sensor_sample),
        .shift_factor  (k_fast),
        .ema_out       (fast_ema)
    );

    ema_filter slow_ema_inst (
        .clk           (clk),
        .rst_n         (rst_n),
        .sample_valid  (sample_valid),
        .sample        (sensor_sample),
        .shift_factor  (k_slow),
        .ema_out       (slow_ema)
    );

    crossover_detector crossover_detector_inst (
        .clk             (clk),
        .rst_n           (rst_n),
        .sample_valid    (sample_valid),
        .fast_ema        (fast_ema),
        .slow_ema        (slow_ema),
        .cross_flag      (cross_flag),
        .trend_direction (trend_direction)
    );

endmodule
