`timescale 1ns / 1ps

module tb_sa_adc;

    reg [7:0] moisture;
    reg [7:0] leaf_temp;
    reg [7:0] humidity;
    reg [7:0] air_temp;
    reg [7:0] light;
    reg [7:0] battery;

    reg [7:0] moisture_t1, moisture_t2;
    reg [7:0] leaf_t1, leaf_t2;
    reg [7:0] humidity_t1, humidity_t2;
    reg [7:0] air_t1, air_t2;
    reg [7:0] light_t1, light_t2;
    reg [7:0] b_crit, b_low;

    wire [7:0] adc_mode_lsb;
    wire [1:0] adc_mode_msb;

    sa_adc_controller uut (
        .moisture(moisture),
        .leaf_temp(leaf_temp),
        .humidity(humidity),
        .air_temp(air_temp),
        .light(light),
        .battery(battery),
        .moisture_t1(moisture_t1), .moisture_t2(moisture_t2),
        .leaf_t1(leaf_t1), .leaf_t2(leaf_t2),
        .humidity_t1(humidity_t1), .humidity_t2(humidity_t2),
        .air_t1(air_t1), .air_t2(air_t2),
        .light_t1(light_t1), .light_t2(light_t2),
        .b_crit(b_crit), .b_low(b_low),
        .adc_mode_lsb(adc_mode_lsb),
        .adc_mode_msb(adc_mode_msb)
    );

    initial begin
        // Initialize thresholds
        moisture_t1 = 8'd100; moisture_t2 = 8'd180;
        leaf_t1     = 8'd120; leaf_t2     = 8'd200;
        humidity_t1 = 8'd110; humidity_t2 = 8'd210;
        air_t1      = 8'd115; air_t2      = 8'd220;
        light_t1    = 8'd130; light_t2    = 8'd230;
        
        b_crit      = 8'd50;
        b_low       = 8'd120;

        // --- TEST 1: Battery Nominal, Adapt according to thresholds ---
        battery = 8'd200; // nominal (> b_low)
        
        // Sensor values below T1 -> Expect 8-bit (2'b00)
        moisture  = 8'd80;
        leaf_temp = 8'd90;
        humidity  = 8'd100;
        air_temp  = 8'd100;
        light     = 8'd110;
        #10;
        $display("[TEST 1A] Nominal Batt, Low Sensors:");
        $display("  adc_mode_lsb: %b (Expected: 00000000)", adc_mode_lsb);
        $display("  adc_mode_msb: %b (Expected: 00)", adc_mode_msb);

        // Sensor values above T1, below T2 -> Expect 10-bit (2'b01)
        moisture  = 8'd150; // > 100
        leaf_temp = 8'd150; // > 120
        humidity  = 8'd150; // > 110
        air_temp  = 8'd150; // > 115
        light     = 8'd150; // > 130
        #10;
        $display("[TEST 1B] Nominal Batt, Mid Sensors (Warning):");
        $display("  adc_mode_lsb: %b (Expected: 01010101)", adc_mode_lsb);
        $display("  adc_mode_msb: %b (Expected: 01)", adc_mode_msb);

        // Sensor values above T2 -> Expect 12-bit (2'b10)
        moisture  = 8'd190; // > 180
        leaf_temp = 8'd210; // > 200
        humidity  = 8'd220; // > 210
        air_temp  = 8'd230; // > 220
        light     = 8'd240; // > 230
        #10;
        $display("[TEST 1C] Nominal Batt, High Sensors (Critical):");
        $display("  adc_mode_lsb: %b (Expected: 10101010)", adc_mode_lsb);
        $display("  adc_mode_msb: %b (Expected: 10)", adc_mode_msb);

        // --- TEST 2: Battery Low, Capped at 10-bit (2'b01) ---
        battery = 8'd100; // low (< b_low, > b_crit)
        #10;
        $display("[TEST 2] Low Batt Override (Capped at 10-bit):");
        $display("  adc_mode_lsb: %b (Expected: 01010101)", adc_mode_lsb);
        $display("  adc_mode_msb: %b (Expected: 01)", adc_mode_msb);

        // --- TEST 3: Battery Critical, Forced to 8-bit (2'b00) ---
        battery = 8'd30; // critical (< b_crit)
        #10;
        $display("[TEST 3] Critical Batt Override (Forced to 8-bit):");
        $display("  adc_mode_lsb: %b (Expected: 00000000)", adc_mode_lsb);
        $display("  adc_mode_msb: %b (Expected: 00)", adc_mode_msb);

        $finish;
    end

endmodule
