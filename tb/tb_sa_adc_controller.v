`timescale 1ns / 1ps

module tb_sa_adc_controller;

    reg [7:0] stress_score;
    reg [2:0] fusion_score;
    reg [7:0] battery_level;

    reg [7:0] moisture_t1, moisture_t2;
    reg [7:0] leaf_t1, leaf_t2;
    reg [7:0] humidity_t1, humidity_t2;
    reg [7:0] air_t1, air_t2;
    reg [7:0] light_t1, light_t2;
    reg [7:0] b_crit, b_low;

    wire [9:0] adc_mode_vector;

    sa_adc_controller uut (
        .stress_score(stress_score),
        .fusion_score(fusion_score),
        .battery_level(battery_level),
        
        .moisture_t1(moisture_t1), .moisture_t2(moisture_t2),
        .leaf_t1(leaf_t1), .leaf_t2(leaf_t2),
        .humidity_t1(humidity_t1), .humidity_t2(humidity_t2),
        .air_t1(air_t1), .air_t2(air_t2),
        .light_t1(light_t1), .light_t2(light_t2),
        
        .b_crit(b_crit), .b_low(b_low),
        .adc_mode_vector(adc_mode_vector)
    );

    initial begin
        // Program default thresholds
        moisture_t1 = 8'd100; moisture_t2 = 8'd180;
        leaf_t1     = 8'd120; leaf_t2     = 8'd200;
        humidity_t1 = 8'd140; humidity_t2 = 8'd210;
        air_t1      = 8'd150; air_t2      = 8'd220;
        light_t1    = 8'd160; light_t2    = 8'd230;

        b_crit      = 8'd51;
        b_low       = 8'd102;

        // Nominal battery
        battery_level = 8'd200;
        fusion_score = 3'd0;

        // Test 1: stress_score = 50 (< all T1) -> Expect all 8-bit (2'b00) -> 10'b00_00_00_00_00
        stress_score = 8'd50;
        #10;
        $display("[ADC TEST 1] stress=50: modes=%b (Expected: 0000000000)", adc_mode_vector);

        // Test 2: stress_score = 110 (moisture T1 is 100, others are >110)
        // moisture -> 10-bit (2'b01), others -> 8-bit (2'b00) -> 10'b00_00_00_00_01
        stress_score = 8'd110;
        #10;
        $display("[ADC TEST 2] stress=110: modes=%b (Expected: 0000000001)", adc_mode_vector);

        // Test 3: stress_score = 155 (moisture T2 is 180, leaf T2 is 200, but moisture T1=100, leaf T1=120, hum T1=140, air T1=150)
        // moisture, leaf, hum, air are 10-bit (2'b01). light is 8-bit (2'b00) -> 10'b00_01_01_01_01
        stress_score = 8'd155;
        #10;
        $display("[ADC TEST 3] stress=155: modes=%b (Expected: 0001010101)", adc_mode_vector);

        // Test 4: context-aware escalation (fusion_score = 2, so Warning/10-bit escalates to Critical/12-bit)
        // moisture, leaf, hum, air are Warning (10-bit). With fusion_score >= 2, they should escalate to Critical (12-bit, 2'b10).
        // light is still 8-bit -> 10'b00_10_10_10_10
        fusion_score = 3'd2;
        #10;
        $display("[ADC TEST 4] stress=155, fusion=2: modes=%b (Expected: 0010101010)", adc_mode_vector);

        // Test 5: low battery override (cap at 10-bit)
        // battery_level = 80 (< b_low), so 12-bit modes are capped to 10-bit -> 10'b00_01_01_01_01
        battery_level = 8'd80;
        #10;
        $display("[ADC TEST 5] stress=155, fusion=2, batt=80 (low): modes=%b (Expected: 0001010101)", adc_mode_vector);

        // Test 6: critical battery override (force all to 8-bit)
        // battery_level = 30 (< b_crit) -> 10'b00_00_00_00_00
        battery_level = 8'd30;
        #10;
        $display("[ADC TEST 6] stress=155, fusion=2, batt=30 (crit): modes=%b (Expected: 0000000000)", adc_mode_vector);

        $finish;
    end

endmodule
