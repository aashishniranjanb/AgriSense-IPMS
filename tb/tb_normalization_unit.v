`timescale 1ns / 1ps

module tb_normalization_unit;

    reg [18:0] weighted_sum_val;
    reg [3:0]  shift_factor;
    wire [7:0] stress_score;

    normalization_unit uut (
        .weighted_sum_val(weighted_sum_val),
        .shift_factor(shift_factor),
        .stress_score(stress_score)
    );

    initial begin
        shift_factor = 4'd6; // default shift factor (div by 64)
        
        // Test 1: below boundary
        weighted_sum_val = 19'd16000; // 16000 / 64 = 250
        #10;
        $display("[NORM TEST 1] sum=16000, shift=6: score=%d (Expected: 250)", stress_score);
        
        // Test 2: exact boundary
        weighted_sum_val = 19'd16320; // 16320 / 64 = 255
        #10;
        $display("[NORM TEST 2] sum=16320, shift=6: score=%d (Expected: 255)", stress_score);

        // Test 3: above boundary
        weighted_sum_val = 19'd16384; // 16384 / 64 = 256 -> clamp to 255
        #10;
        $display("[NORM TEST 3] sum=16384, shift=6: score=%d (Expected: 255)", stress_score);

        // Test 4: extreme value
        weighted_sum_val = 19'd30000; // clamp to 255
        #10;
        $display("[NORM TEST 4] sum=30000, shift=6: score=%d (Expected: 255)", stress_score);

        // Test 5: different shift factor (e.g. shift = 10)
        shift_factor = 4'd10; // div by 1024
        weighted_sum_val = 19'd256000; // 256000 / 1024 = 250
        #10;
        $display("[NORM TEST 5] sum=256000, shift=10: score=%d (Expected: 250)", stress_score);

        $finish;
    end

endmodule
