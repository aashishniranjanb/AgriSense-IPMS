`timescale 1ns / 1ps

module tb_adc_mode_transition;

    reg clk;
    reg rst_n;

    // SPI / Register Bus interface
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
    reg       wake_timer;

    // Outputs
    wire [3:0] leaf_output;
    wire [1:0] ipm_state;
    wire       domain2_pwr_en;
    wire       domain3_pwr_en;
    wire       comm_en_out;
    wire [9:0] adc_mode_vector;

    // Instantiate Top Module
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

    // Clock Gen: 100MHz (10ns period)
    always #5 clk = ~clk;

    // Register Write Task
    task reg_write(input [7:0] addr, input [7:0] data);
        begin
            @(posedge clk);
            m_addr = addr;
            m_wdata = data;
            m_we = 1;
            @(posedge clk);
            m_we = 0;
        end
    endtask

    // Sample Send Task
    task send_sample(input [7:0] m, input [7:0] batt);
        begin
            @(posedge clk);
            moisture = m;
            battery = batt;
            sample_valid = 1;
            @(posedge clk);
            sample_valid = 0;
            repeat(10) @(posedge clk); // Allow time for filters/CSA/isolation
        end
    endtask

    initial begin
        $dumpfile("adc_mode_transition.vcd");
        // Dump relevant signals for GTKWave Fig 4
        $dumpvars(0, clk);
        $dumpvars(0, rst_n);
        $dumpvars(0, sample_valid);
        
        // Inputs affecting ADC mode
        $dumpvars(0, battery);
        $dumpvars(0, moisture); // Acts as stress/variance driver
        
        // Internals & Outputs
        $dumpvars(0, uut.stress_score_iso);
        $dumpvars(0, uut.u_sa_adc.fusion_score);
        
        // Mode outputs for moisture channel (bits [1:0] of vector) and top level vector
        $dumpvars(0, uut.u_sa_adc.mode_moisture);
        $dumpvars(0, adc_mode_vector);

        // Init inputs
        clk = 0;
        rst_n = 0;
        m_addr = 0;
        m_wdata = 0;
        m_we = 0;
        m_re = 0;
        sample_valid = 0;
        moisture = 8'd80;
        leaf_temp = 8'd0;
        humidity = 8'd0;
        air_temp = 8'd0;
        light = 8'd0;
        battery = 8'd200; // High battery
        wake_timer = 0;

        #50;
        rst_n = 1;
        #50;

        // Configure register file
        // Weights: w_moisture = 64, others = 0.
        // This maps the stress_score exactly to the moisture sample.
        reg_write(8'h10, 8'd64); // w_moisture
        reg_write(8'h11, 8'd0);  // w_leaftemp
        reg_write(8'h12, 8'd0);  // w_humidity
        reg_write(8'h13, 8'd0);  // w_airtemp
        reg_write(8'h14, 8'd0);  // w_light
        reg_write(8'h19, 8'd6);  // Normalization shift = 6 (divide by 64)

        // SA-ADC Thresholds for moisture channel
        reg_write(8'h80, 8'd100); // MOISTURE_T1
        reg_write(8'h81, 8'd180); // MOISTURE_T2
        
        // Battery thresholds
        reg_write(8'h8A, 8'd50);  // B_CRIT
        reg_write(8'h8B, 8'd120); // B_LOW

        // Wake IPM to MONITOR and then to COMPUTE by triggering stress
        @(posedge clk);
        wake_timer = 1;
        @(posedge clk);
        wake_timer = 0;
        repeat(5) @(posedge clk);

        // Force IPM to activate Domain 2 (Compute) so that stress_score_iso is unisolated/active.
        // We do this by triggering a decde stress event or manually enabling components, or simply
        // driving the IPM into warning/critical.
        // Wait, the FSM transitions to COMPUTE when stress_event is high.
        // Let's configure fusion threshold = 1 and trigger a crossover.
        reg_write(8'h20, 8'd2); // moisture shift factor
        reg_write(8'h52, 8'd1); // fusion vote threshold = 1
        reg_write(8'h51, 8'd8); // fusion window size = 8
        reg_write(8'h55, 8'h00); // fusion pattern
        reg_write(8'h56, 8'h00);

        // Send a step in moisture to trigger crossover -> stress_event -> IPM transitions to COMPUTE -> domain2_pwr_en goes high!
        $display("Waking up IPM to COMPUTE state...");
        send_sample(8'd150, 8'd200); // Jump to 150 to trigger crossover

        // Now that Domain 2 is powered on (domain2_pwr_en = 1), the stress score is active and unisolated.
        // Let's sweep moisture and battery to show transitions:

        // Stage 1: Battery High (200), Low Stress (moisture = 80) -> Expect Mode = 8-bit (2'b00)
        $display("Stage 1: Battery High, Low Stress");
        send_sample(8'd80, 8'd200);

        // Stage 2: Battery High (200), Medium Stress (moisture = 140) -> Expect Mode = 10-bit (2'b01)
        $display("Stage 2: Battery High, Medium Stress");
        send_sample(8'd140, 8'd200);

        // Stage 3: Battery High (200), High Stress (moisture = 220) -> Expect Mode = 12-bit (2'b10)
        $display("Stage 3: Battery High, High Stress");
        send_sample(8'd220, 8'd200);

        // Stage 4: Battery Low (100) caps mode to 10-bit (2'b01) even if stress is High (moisture = 220)
        $display("Stage 4: Battery Low, High Stress");
        send_sample(8'd220, 8'd100);

        // Stage 5: Battery Critical (40) forces mode to 8-bit (2'b00) even if stress is High (moisture = 220)
        $display("Stage 5: Battery Critical, High Stress");
        send_sample(8'd220, 8'd40);

        #100;
        $display("Simulation complete. VCD dumped.");
        $finish;
    end

endmodule
