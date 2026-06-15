`timescale 1ns / 1ps

module tb_fusion_waveform;

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
    task send_sample(input [7:0] m, input [7:0] lt, input [7:0] h);
        begin
            @(posedge clk);
            moisture = m;
            leaf_temp = lt;
            humidity = h;
            sample_valid = 1;
            @(posedge clk);
            sample_valid = 0;
            repeat(10) @(posedge clk); // Allow time for filters to compute
        end
    endtask

    initial begin
        $dumpfile("fusion_waveform.vcd");
        // Dump relevant signals for GTKWave Fig 3
        $dumpvars(0, clk);
        $dumpvars(0, rst_n);
        $dumpvars(0, sample_valid);
        $dumpvars(0, moisture);
        $dumpvars(0, leaf_temp);
        $dumpvars(0, humidity);
        
        // Internal EMA and Crossover signals
        $dumpvars(0, uut.u_decde_0.fast_ema);
        $dumpvars(0, uut.u_decde_0.slow_ema);
        $dumpvars(0, uut.u_decde_0.cross_flag);
        
        $dumpvars(0, uut.u_decde_1.fast_ema);
        $dumpvars(0, uut.u_decde_1.slow_ema);
        $dumpvars(0, uut.u_decde_1.cross_flag);

        $dumpvars(0, uut.u_decde_2.fast_ema);
        $dumpvars(0, uut.u_decde_2.slow_ema);
        $dumpvars(0, uut.u_decde_2.cross_flag);
        
        // Fusion Unit outputs
        $dumpvars(0, uut.cross_flag_vector);
        $dumpvars(0, uut.u_fusion.fusion_score);
        $dumpvars(0, uut.stress_event);

        // Init inputs
        clk = 0;
        rst_n = 0;
        m_addr = 0;
        m_wdata = 0;
        m_we = 0;
        m_re = 0;
        sample_valid = 0;
        moisture = 8'd80;
        leaf_temp = 8'd70;
        humidity = 8'd60;
        air_temp = 8'd75;
        light = 8'd100;
        battery = 8'd200;
        wake_timer = 0;

        #50;
        rst_n = 1;
        #50;

        // Configure register file
        // Weights that sum to 64
        reg_write(8'h10, 8'd20); // w_moisture
        reg_write(8'h11, 8'd20); // w_leaftemp
        reg_write(8'h12, 8'd10); // w_humidity
        reg_write(8'h13, 8'd10); // w_airtemp
        reg_write(8'h14, 8'd4);  // w_light
        reg_write(8'h19, 8'd6);  // Normalization shift

        // Set shift factors to 2 (Fast EMA = shift 2, Slow EMA = shift 4)
        reg_write(8'h20, 8'd2);
        reg_write(8'h21, 8'd2);
        reg_write(8'h22, 8'd2);
        reg_write(8'h23, 8'd2);
        reg_write(8'h24, 8'd2);

        // Fusion config: threshold = 2, window = 8
        reg_write(8'h52, 8'd2); 
        reg_write(8'h51, 8'd8);

        // Pattern config: all 0 (Don't Care, triggers on any transition)
        reg_write(8'h55, 8'h00);
        reg_write(8'h56, 8'h00);

        // Wake IPM to MONITOR
        @(posedge clk);
        wake_timer = 1;
        @(posedge clk);
        wake_timer = 0;
        repeat(5) @(posedge clk);

        // Start driving nominal values
        $display("Sending nominal samples...");
        send_sample(8'd80, 8'd70, 8'd60);
        send_sample(8'd80, 8'd70, 8'd60);
        send_sample(8'd80, 8'd70, 8'd60);

        // Step 1: Moisture Stress Event (sudden increase)
        $display("Driving Moisture Stress...");
        send_sample(8'd140, 8'd70, 8'd60); // Sudden jump causing EMA crossover
        send_sample(8'd140, 8'd70, 8'd60);

        // Step 2: Temperature Stress Event (lagged crossover)
        $display("Driving Temperature Stress...");
        send_sample(8'd140, 8'd130, 8'd60); // Sudden jump in temperature
        send_sample(8'd140, 8'd130, 8'd60);

        // Step 3: Observe Fusion Alert
        $display("Observing Fusion Alert...");
        send_sample(8'd140, 8'd130, 8'd60);
        send_sample(8'd140, 8'd130, 8'd60);

        #100;
        $display("Simulation complete. VCD dumped.");
        $finish;
    end

endmodule
