`timescale 1ns / 1ps

module tb_top;

    reg clk;
    reg rst_n;

    // SPI / Register Bus interface (Master)
    reg [7:0] m_addr;
    reg [7:0] m_wdata;
    reg       m_we;
    reg       m_re;
    wire [7:0] m_rdata;

    // Sensor Interfaces
    reg       sample_valid;
    reg [7:0] moisture;
    reg [7:0] leaf_temp;
    reg [7:0] humidity;
    reg [7:0] air_temp;
    reg [7:0] light;
    reg [7:0] battery;

    // Timers
    reg       wake_timer;

    // Status / Outputs
    wire [3:0] leaf_output;
    wire [1:0] ipm_state;
    wire       domain2_pwr_en;
    wire       domain3_pwr_en;
    wire       comm_en_out;
    wire [9:0] adc_mode_vector;

    agrisense_ipms_top uut (
        .clk(clk),
        .rst_n(rst_n),
        .m_addr(m_addr),
        .m_wdata(m_wdata),
        .m_we(m_we),
        .m_re(m_re),
        .m_rdata(m_rdata),
        .sample_valid(sample_valid),
        .moisture(moisture),
        .leaf_temp(leaf_temp),
        .humidity(humidity),
        .air_temp(air_temp),
        .light(light),
        .battery(battery),
        .wake_timer(wake_timer),
        .leaf_output(leaf_output),
        .ipm_state(ipm_state),
        .domain2_pwr_en(domain2_pwr_en),
        .domain3_pwr_en(domain3_pwr_en),
        .comm_en_out(comm_en_out),
        .adc_mode_vector(adc_mode_vector)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Task to write to register file
    task reg_write;
        input [7:0] addr;
        input [7:0] data;
        begin
            @(posedge clk);
            m_addr = addr;
            m_wdata = data;
            m_we = 1;
            @(posedge clk);
            m_we = 0;
        end
    endtask

    // Task to send a sensor sample
    task send_sample;
        input [7:0] m, lt, h, at, l;
        begin
            @(posedge clk);
            moisture = m;
            leaf_temp = lt;
            humidity = h;
            air_temp = at;
            light = l;
            sample_valid = 1;
            @(posedge clk);
            sample_valid = 0;
            // Wait some cycles for EMA filter to process
            repeat(5) @(posedge clk);
        end
    endtask

    initial begin
        $dumpfile("tb_top.vcd");
`ifdef DUMP_ALL
        $dumpvars(0, uut);
`else
        // Dump specific architecture signals as requested
        $dumpvars(0, uut.ipm_state);
        $dumpvars(0, uut.cross_flag_vector);
        $dumpvars(0, uut.fusion_score);
        $dumpvars(0, uut.stress_event);
        $dumpvars(0, uut.domain2_pwr_en);
        $dumpvars(0, uut.stress_score_iso);
        $dumpvars(0, uut.leaf_output);
        $dumpvars(0, uut.adc_mode_lsb);
        $dumpvars(0, uut.adc_mode_msb);
        $dumpvars(0, adc_mode_vector);
        $dumpvars(0, battery);
`endif

        // Initialize Inputs
        clk = 0;
        rst_n = 0;
        m_addr = 0;
        m_wdata = 0;
        m_we = 0;
        m_re = 0;
        sample_valid = 0;
        moisture = 120;
        leaf_temp = 100;
        humidity = 110;
        air_temp = 105;
        light = 115;
        battery = 200; // nominal battery
        wake_timer = 0;

        // Wait 100 ns for global reset
        #100;
        rst_n = 1;
        #20;

        // --- Initialization ---
        $display("--- Initialization: Programming Register File ---");
        
        // 1. Program weights that do not sum to 64 (sum = 250)
        reg_write(8'h10, 8'd50); // w_moisture
        reg_write(8'h11, 8'd50); // w_leaftemp
        reg_write(8'h12, 8'd50); // w_humidity
        reg_write(8'h13, 8'd50); // w_airtemp
        reg_write(8'h14, 8'd50); // w_light
        
        // Read REG_WEIGHT_STATUS (should return 0)
        @(posedge clk);
        m_addr = 8'h1A;
        m_re = 1;
        #1;
        $display("  [Weight Invariant Check 1] Weights sum = 250: REG_WEIGHT_STATUS = %h (Expected: 00)", m_rdata);
        if (m_rdata[0] !== 1'b0) begin
            $display("ERROR: weights_valid was 1 when weights sum is 250!");
            $finish;
        end
        @(posedge clk);
        m_re = 0;

        // 2. Program weights that sum to 64 (13, 13, 13, 13, 12)
        reg_write(8'h10, 8'd13); // w_moisture
        reg_write(8'h11, 8'd13); // w_leaftemp
        reg_write(8'h12, 8'd13); // w_humidity
        reg_write(8'h13, 8'd13); // w_airtemp
        reg_write(8'h14, 8'd12); // w_light

        // Read REG_WEIGHT_STATUS (should return 1)
        @(posedge clk);
        m_addr = 8'h1A;
        m_re = 1;
        #1;
        $display("  [Weight Invariant Check 2] Weights sum = 64: REG_WEIGHT_STATUS = %h (Expected: 01)", m_rdata);
        if (m_rdata[0] !== 1'b1) begin
            $display("ERROR: weights_valid was 0 when weights sum is 64!");
            $finish;
        end
        @(posedge clk);
        m_re = 0;
        
        // CSA Scaling shift factor (0x19)
        reg_write(8'h19, 8'd6);  // Normalization shift = 6 (div 64)

        // Program Fusion Pattern: Falling Moisture (2'b10), Rising Leaf Temp (2'b01), others Don't Care (2'b00)
        // fusion_pattern_reg[9:0] = {2'b00 (light), 2'b00 (airtemp), 2'b00 (humidity), 2'b01 (leaftemp), 2'b10 (moisture)} = 10'b0000000110 (8'h06 LSB, 8'h00 MSB)
        reg_write(8'h55, 8'h06); // Pattern LSB
        reg_write(8'h56, 8'h00); // Pattern MSB

        // Shift Factors (0x20-0x24) - Set to 2
        reg_write(8'h20, 8'd2);
        reg_write(8'h21, 8'd2);
        reg_write(8'h22, 8'd2);
        reg_write(8'h23, 8'd2);
        reg_write(8'h24, 8'd2);

        // Fusion Vote Threshold (0x52)
        reg_write(8'h52, 8'd2); // Need 2 sensors to trigger stress_event
        // Fusion Window Size (0x51)
        reg_write(8'h51, 8'd3); // Set temporal window = 3 cycles

        // Decision Tree Thresholds (0x60-0x66)
        reg_write(8'h60, 8'd10);  // T0: Stress Score Threshold
        reg_write(8'h61, 8'd1);   // T1: Fusion Score Threshold
        reg_write(8'h62, 8'd80);  // T2: Moisture
        reg_write(8'h63, 8'd100); // T3: LeafTemp
        reg_write(8'h64, 8'd90);  // T4: Humidity
        reg_write(8'h65, 8'd100); // T5: AirTemp
        reg_write(8'h66, 8'd100); // T6: Light

        // SA-ADC Thresholds (0x80 - 0x8B)
        reg_write(8'h80, 8'd100); // MOISTURE_T1
        reg_write(8'h81, 8'd180); // MOISTURE_T2
        reg_write(8'h82, 8'd120); // LEAF_T1
        reg_write(8'h83, 8'd200); // LEAF_T2
        reg_write(8'h84, 8'd110); // HUMIDITY_T1
        reg_write(8'h85, 8'd210); // HUMIDITY_T2
        reg_write(8'h86, 8'd115); // AIR_T1
        reg_write(8'h87, 8'd220); // AIR_T2
        reg_write(8'h88, 8'd130); // LIGHT_T1
        reg_write(8'h89, 8'd230); // LIGHT_T2
        reg_write(8'h8A, 8'd50);  // B_CRIT
        reg_write(8'h8B, 8'd120); // B_LOW

        // Wake IPM to MONITOR state
        @(posedge clk);
        wake_timer = 1;
        @(posedge clk);
        wake_timer = 0;
        repeat(5) @(posedge clk);

        // --- Scenario 1: Nominal Conditions ---
        $display("--- Scenario 1: Nominal Conditions ---");
        repeat(10) send_sample(120, 100, 110, 105, 115);
        #100;
        
        // --- Scenario 2: Water Stress Development ---
        $display("--- Scenario 2: Water Stress Development ---");
        send_sample(118, 100, 110, 105, 115);
        send_sample(115, 100, 110, 105, 115);
        send_sample(110, 100, 110, 105, 115);
        send_sample(105, 100, 110, 105, 115);
        send_sample(100, 100, 110, 105, 115);
        send_sample(95,  100, 110, 105, 115);
        send_sample(90,  100, 110, 105, 115);
        send_sample(85,  100, 110, 105, 115);
        send_sample(80,  100, 110, 105, 115);
        #100;

        // --- Scenario 3: Multi-Sensor Correlation ---
        $display("--- Scenario 3: Multi-Sensor Correlation ---");
        send_sample(75, 105, 105, 105, 115);
        send_sample(70, 110, 100, 105, 115);
        send_sample(65, 115, 95,  105, 115);
        send_sample(60, 120, 90,  105, 115);
        send_sample(55, 125, 85,  105, 115);
        #100;

        // --- Scenario 4: Domain 2 Activation ---
        $display("--- Scenario 4: Domain 2 Activation ---");
        #100;

        // --- Scenario 5: Stress Classification & Battery Override ---
        $display("--- Scenario 5: Stress Classification & Battery Override ---");
        // Push extreme values to ensure high stress_score (should saturate to 255)
        send_sample(255, 255, 255, 255, 255);
        #50;
        
        $display("  [Scenario 5A] Checking High Resolution Mode on Nominal Battery...");
        #50;
        
        $display("  [Scenario 5B] Switching to Low Battery (100) -> Resolutions should cap at 10-bit (2'b01)");
        battery = 8'd100;
        #50;
        
        $display("  [Scenario 5C] Switching to Critical Battery (30) -> Resolutions should force to 8-bit (2'b00)");
        battery = 8'd30;
        #50;

        // Restore battery
        battery = 8'd200;
        #100;

        // --- Scenario 6: Recovery ---
        $display("--- Scenario 6: Recovery ---");
        send_sample(100, 110, 100, 105, 115);
        send_sample(110, 105, 105, 105, 115);
        send_sample(120, 100, 110, 105, 115);
        send_sample(120, 100, 110, 105, 115);
        send_sample(120, 100, 110, 105, 115);
        send_sample(120, 100, 110, 105, 115);
        #100;
        
        $finish;
    end
endmodule
