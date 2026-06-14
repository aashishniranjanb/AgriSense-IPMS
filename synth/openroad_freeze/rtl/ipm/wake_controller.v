module wake_controller (
    input  wire clk,
    input  wire rst_n,
    
    input  wire wake_timer_raw,
    input  wire sample_valid_raw,

    output wire wake_timer_sync,
    output wire sample_valid_sync
);

    synchronizer sync_wake (
        .clk(clk),
        .rst_n(rst_n),
        .async_in(wake_timer_raw),
        .sync_out(wake_timer_sync)
    );

    synchronizer sync_sample (
        .clk(clk),
        .rst_n(rst_n),
        .async_in(sample_valid_raw),
        .sync_out(sample_valid_sync)
    );

endmodule
