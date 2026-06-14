module synchronizer (
    input  wire clk,
    input  wire rst_n,
    input  wire async_in,
    output reg  sync_out
);

    reg q1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q1       <= 1'b0;
            sync_out <= 1'b0;
        end else begin
            q1       <= async_in;
            sync_out <= q1;
        end
    end

endmodule
