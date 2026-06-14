`timescale 1ns / 1ps

module tb_csa;

    reg [7:0] moisture;
    reg [7:0] leaf_temp;
    reg [7:0] humidity;
    reg [7:0] air_temp;
    reg [7:0] light;

    reg [7:0] w_moisture;
    reg [7:0] w_leaftemp;
    reg [7:0] w_humidity;
    reg [7:0] w_airtemp;
    reg [7:0] w_light;

    reg csa_en;

    wire [7:0] stress_score;

    crop_stress_accelerator dut (
        .moisture(moisture),
        .leaf_temp(leaf_temp),
        .humidity(humidity),
        .air_temp(air_temp),
        .light(light),
        .w_moisture(w_moisture),
        .w_leaftemp(w_leaftemp),
        .w_humidity(w_humidity),
        .w_airtemp(w_airtemp),
        .w_light(w_light),
        .csa_en(csa_en),
        .stress_score(stress_score)
    );

    initial begin
        $dumpfile("tb_csa.vcd");
        $dumpvars(0, tb_csa);
        
        // Initialize
        moisture = 0; leaf_temp = 0; humidity = 0; air_temp = 0; light = 0;
        w_moisture = 0; w_leaftemp = 0; w_humidity = 0; w_airtemp = 0; w_light = 0;
        csa_en = 0;

        #10;
        csa_en = 1;

        // Test 1: All zero
        #10;
        $display("--- Test 1: All zero ---");
        // Already 0
        #10;
        $display("Stress Score: %d (Expected: 0)", stress_score);
        if (stress_score !== 8'd0) $display("PASS"); else $display("FAIL");

        // Test 2: Maximum
        #10;
        $display("--- Test 2: Maximum ---");
        moisture = 255; leaf_temp = 255; humidity = 255; air_temp = 255; light = 255;
        w_moisture = 255; w_leaftemp = 255; w_humidity = 255; w_airtemp = 255; w_light = 255;
        #10;
        $display("Stress Score: %d (Expected: 158 [No overflow])", stress_score);

        // Test 3: Moisture Dominates
        #10;
        $display("--- Test 3: Moisture Dominates ---");
        moisture = 255; leaf_temp = 100; humidity = 100; air_temp = 100; light = 100;
        w_moisture = 200; w_leaftemp = 10; w_humidity = 10; w_airtemp = 10; w_light = 10;
        #10;
        $display("Stress Score: %d (Expected: Strongly influenced by moisture)", stress_score);

        // Test 4: Uniform Weights
        #10;
        $display("--- Test 4: Uniform Weights ---");
        moisture = 150; leaf_temp = 150; humidity = 150; air_temp = 150; light = 150;
        w_moisture = 100; w_leaftemp = 100; w_humidity = 100; w_airtemp = 100; w_light = 100;
        #10;
        $display("Stress Score: %d (Expected: Balanced contribution)", stress_score);
        
        #10;
        $display("All tests completed.");
        $finish;
    end
endmodule
