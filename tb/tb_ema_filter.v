module tb_ema_filter;

    reg        clk;
    reg        rst_n;
    reg        sample_valid;
    reg  [7:0] sample;
    reg  [2:0] shift_factor;

    wire [15:0] ema_out;

    ema_filter dut (
        .clk(clk),
        .rst_n(rst_n),
        .sample_valid(sample_valid),
        .sample(sample),
        .shift_factor(shift_factor),
        .ema_out(ema_out)
    );

    always #5 clk = ~clk;

    task send_sample;
        input [7:0] val;
        begin
            @(posedge clk);
            sample       <= val;
            sample_valid <= 1'b1;
            @(posedge clk);
            sample_valid <= 1'b0;
            #20;
        end
    endtask

    initial begin
        clk          = 0;
        rst_n        = 0;
        sample_valid = 0;
        sample       = 0;
        shift_factor = 3'd1; // Quick convergence

        #25 rst_n = 1;

        $display("\n=== Test 1: Constant ===");
        send_sample(8'd50);
        send_sample(8'd50);
        send_sample(8'd50);
        send_sample(8'd50);
        send_sample(8'd50);

        #50 rst_n = 0; #20 rst_n = 1;
        $display("\n=== Test 2: Smooth Rise ===");
        send_sample(8'd50);
        send_sample(8'd60);
        send_sample(8'd70);
        send_sample(8'd80);
        send_sample(8'd90);

        #50 rst_n = 0; #20 rst_n = 1;
        $display("\n=== Test 3: Smooth Fall ===");
        send_sample(8'd90);
        send_sample(8'd80);
        send_sample(8'd70);
        send_sample(8'd60);
        send_sample(8'd50);

        #50;
        $display("EMA tests complete.\n");
        $finish;
    end

    // Monitor Output
    always @(posedge clk) begin
        if (sample_valid) begin
            #10 $display("[%0t] Sample: %3d | EMA Out: %3d.%02d", 
                         $time, sample, ema_out[15:8], (ema_out[7:0] * 100)/256);
        end
    end

endmodule
