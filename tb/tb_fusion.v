module tb_fusion;

    reg        clk;
    reg        rst_n;
    reg  [4:0] cross_flag_vector;
    reg  [2:0] vote_threshold;

    wire [2:0] fusion_score;
    wire       stress_event;

    fusion_unit dut (
        .clk(clk),
        .rst_n(rst_n),
        .cross_flag_vector(cross_flag_vector),
        .vote_threshold(vote_threshold),
        .fusion_score(fusion_score),
        .stress_event(stress_event)
    );

    always #5 clk = ~clk;

    task test_vector;
        input [4:0] vec;
        input [2:0] expected_score;
        input       expected_event;
        begin
            @(negedge clk); // Setup data before clock edge
            cross_flag_vector <= vec;
            @(posedge clk); // Clock the input to the combinatorial block
            @(posedge clk); // Clock the result into the sequential registers
            #1;             // Small delay to allow simulation to update values for display
            
            $display("Input Vector: %b | Expected: score=%d, event=%b | Actual: score=%d, event=%b", 
                     vec, expected_score, expected_event, fusion_score, stress_event);
                     
            if (fusion_score !== expected_score || stress_event !== expected_event) begin
                $display("ERROR: Mismatch detected!");
            end
        end
    endtask

    initial begin
        clk = 0;
        rst_n = 0;
        cross_flag_vector = 5'b00000;
        vote_threshold = 3'd2; // Set threshold to 2 based on test cases

        #25 rst_n = 1;

        $display("\n=== Fusion Unit v0.1 Tests (Threshold = 2) ===");
        
        // Case 1: 00000 -> score = 0, event = 0
        test_vector(5'b00000, 3'd0, 1'b0);
        
        // Case 2: 10000 -> score = 1, event = 0
        test_vector(5'b10000, 3'd1, 1'b0);
        
        // Case 3: 10100 -> score = 2, event = 1
        test_vector(5'b10100, 3'd2, 1'b1);
        
        // Case 4: 11111 -> score = 5, event = 1
        test_vector(5'b11111, 3'd5, 1'b1);

        #20;
        $display("\nFusion v0.1 Tests complete.\n");
        $finish;
    end

endmodule
