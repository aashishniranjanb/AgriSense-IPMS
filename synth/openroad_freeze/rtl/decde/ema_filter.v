module ema_filter(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        sample_valid,
    input  wire [7:0]  sample,
    input  wire [2:0]  shift_factor,
    output reg  [15:0] ema_out
);

    wire [15:0] sample_fixed;
    assign sample_fixed = {sample, 8'h00};
    
    // ASIC DESIGN RTL TUNING:
    // To prevent catastrophic overflow/underflow when difference > 127
    // (since Q8.8 represents 0-255), delta MUST be 17-bit signed.
    // If we used a 16-bit signed delta, 255.0 - 0.0 would overflow to -256
    // and corrupt the arithmetic shift right (>>>).
    wire signed [16:0] delta;
    assign delta = $signed({1'b0, sample_fixed}) - $signed({1'b0, ema_out});

    reg initialized;

    /* verilator lint_off UNUSEDSIGNAL */
    wire signed [16:0] next_ema;
    /* verilator lint_on UNUSEDSIGNAL */
    assign next_ema = $signed({1'b0, ema_out}) + (delta >>> shift_factor);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ema_out     <= 16'h0000;
            initialized <= 1'b0;
        end else if (sample_valid) begin
            if (!initialized) begin
                ema_out     <= sample_fixed; // Mandatory first valid sample init
                initialized <= 1'b1;
            end else begin
                // Signed addition with the correctly sign-extended arithmetic shift
                ema_out     <= $unsigned(next_ema[15:0]);
            end
        end
    end

endmodule
