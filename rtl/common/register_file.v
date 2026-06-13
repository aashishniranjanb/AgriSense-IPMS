`include "agrisense_defs.vh"

module register_file(
    input  wire       clk,
    input  wire       rst_n,

    input  wire [7:0] addr,
    input  wire [7:0] wdata,

    input  wire       we,
    input  wire       re,

    output reg  [7:0] rdata
);

    // 256 x 8-bit registers (Always-On Domain Storage)
    reg [7:0] reg_mem [0:255];

    integer i;

    // Write Logic with critical RESET fix
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            // LEVEL 3 CHECK: All registers known after reset. No X values.
            for(i=0; i<256; i=i+1) begin
                reg_mem[i] <= 8'h00;
            end
        end else if(we) begin
            reg_mem[addr] <= wdata;
        end
    end

    // Read Logic
    always @(*) begin
        if(re)
            rdata = reg_mem[addr];
        else
            rdata = 8'h00;
    end

endmodule
