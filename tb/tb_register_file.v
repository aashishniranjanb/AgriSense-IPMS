`include "agrisense_defs.vh"

module tb_register_file;
    reg clk;
    reg rst_n;
    reg [7:0] addr;
    reg [7:0] wdata;
    reg we;
    reg re;
    wire [7:0] rdata;

    register_file dut (
        .clk(clk),
        .rst_n(rst_n),
        .addr(addr),
        .wdata(wdata),
        .we(we),
        .re(re),
        .rdata(rdata)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0; rst_n = 0;
        addr = 0; wdata = 0; we = 0; re = 0;
        
        #25 rst_n = 1;

        $display("\n=== Register File Tests ===");

        // Test: Write 0x55 to 0x10
        @(negedge clk);
        addr = 8'h10; wdata = 8'h55; we = 1;
        @(negedge clk);
        we = 0;

        // Test: Read 0x10
        @(negedge clk);
        addr = 8'h10; re = 1;
        @(negedge clk);
        if (rdata === 8'h55) $display("PASS: Read 0x10 = 0x55");
        else $display("FAIL: Read 0x10 = 0x%h", rdata);
        
        // Test: Read Disabled
        @(negedge clk);
        re = 0;
        @(negedge clk);
        if (rdata === 8'h00) $display("PASS: Read Disabled = 0x00");
        else $display("FAIL: Read Disabled = 0x%h", rdata);

        $display("Register File Tests Complete.\n");
        $finish;
    end
endmodule
