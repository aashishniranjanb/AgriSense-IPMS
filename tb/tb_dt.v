`timescale 1ns / 1ps

module tb_dt;

    // Inputs
    reg [7:0] moisture;
    reg [7:0] leaf_temp;
    reg [7:0] humidity;
    reg [7:0] air_temp;
    reg [7:0] light;
    reg [7:0] stress_score;
    reg [2:0] fusion_score;
    reg stress_event;

    reg [7:0] t0;
    reg [7:0] t1;
    reg [7:0] t2;
    reg [7:0] t3;
    reg [7:0] t4;
    reg [7:0] t5;
    reg [7:0] t6;

    // Outputs
    wire [3:0] leaf_output;

    // Instantiate the Unit Under Test (UUT)
    decision_tree_accelerator uut (
        .moisture(moisture),
        .leaf_temp(leaf_temp),
        .humidity(humidity),
        .air_temp(air_temp),
        .light(light),
        .stress_score(stress_score),
        .fusion_score(fusion_score),
        .stress_event(stress_event),
        .t0(t0),
        .t1(t1),
        .t2(t2),
        .t3(t3),
        .t4(t4),
        .t5(t5),
        .t6(t6),
        .leaf_output(leaf_output)
    );

    initial begin
        $dumpfile("tb_dt.vcd");
        $dumpvars(0, tb_dt);
        
        // Initialize Inputs
        moisture = 0; leaf_temp = 0; humidity = 0; air_temp = 0; light = 0;
        stress_score = 0; fusion_score = 0; stress_event = 0;
        t0 = 100; t1 = 3; t2 = 50; t3 = 60; t4 = 70; t5 = 80; t6 = 90;

        #10;
        // Test 1: No stress event
        $display("--- Test 1: No stress event ---");
        stress_event = 0;
        #10;
        if (leaf_output == 4'b0000) $display("PASS: Output is NORMAL");
        else $display("FAIL");

        // Test 2: Stress event triggered, trace left-most path
        $display("--- Test 2: Left-most path (NORMAL via tree) ---");
        stress_event = 1;
        stress_score = 50;  // < t0 (100) -> left
        fusion_score = 2;   // < t1 (3)   -> left
        leaf_temp = 40;     // < t3 (60)  -> left
        #10;
        if (leaf_output == 4'b0000) $display("PASS: Output is NORMAL");
        else $display("FAIL");

        // Test 3: Trace right-most path
        $display("--- Test 3: Right-most path (MULTI_FACTOR_EVENT) ---");
        stress_score = 150; // >= t0 (100) -> right
        moisture = 80;      // >= t2 (50)  -> right
        light = 120;        // >= t6 (90)  -> right
        #10;
        if (leaf_output == 4'b1111) $display("PASS: Output is MULTI_FACTOR_EVENT");
        else $display("FAIL");

        // Test 4: Mixed path (High Stress)
        $display("--- Test 4: Mixed path (HIGH_STRESS) ---");
        stress_score = 50;  // < t0 (100) -> left
        fusion_score = 5;   // >= t1 (3)  -> right
        humidity = 80;      // >= t4 (70) -> right
        #10;
        if (leaf_output == 4'b1100) $display("PASS: Output is HIGH_STRESS");
        else $display("FAIL");
        
        #10;
        $display("All tests completed.");
        $finish;
    end
endmodule
