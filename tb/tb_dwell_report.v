`timescale 1ns / 1ps
`include "agrisense_defs.vh"

// =============================================================
// tb_dwell_report.v
// Dwell-Time Report Testbench — AgriSense-IPMS v1.0
// Validates Contribution #3: Hierarchical Wake Pipeline
// Runs: correlated_stress_01/02/03 traces and reports:
//   - MONITOR / WARNING / CRITICAL dwell times
//   - Number of state transitions
//   - Average WARNING and CRITICAL dwell
// =============================================================

module tb_dwell_report;

    reg clk;
    reg rst_n;

    // Register bus
    reg  [7:0] m_addr;
    reg  [7:0] m_wdata;
    reg        m_we;
    reg        m_re;
    wire [7:0] m_rdata;

    // Sensor inputs
    reg [7:0] moisture;
    reg [7:0] leaf_temp;
    reg [7:0] humidity;
    reg [7:0] air_temp;
    reg [7:0] light;
    reg [7:0] battery;
    reg       sample_valid;
    reg       wake_timer;

    // Outputs
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

    always #5 clk = ~clk;

    // --- Register write task ---
    task reg_write;
        input [7:0] addr;
        input [7:0] data;
        begin
            @(posedge clk); m_addr = addr; m_wdata = data; m_we = 1;
            @(posedge clk); m_we = 0;
        end
    endtask

    // --- Send a single sample and wait settle ---
    task push_sample;
        input [7:0] m, lt, h, at, l;
        begin
            @(posedge clk);
            moisture  = m;  leaf_temp = lt; humidity = h;
            air_temp  = at; light     = l;
            sample_valid = 1;
            @(posedge clk);
            sample_valid = 0;
            repeat(4) @(posedge clk);
        end
    endtask

    // ---- Dwell-time counters -----
    integer monitor_dwell;
    integer warning_dwell;
    integer critical_dwell;
    integer n_transitions;
    integer total_warning_dwell;
    integer total_critical_dwell;
    integer n_warning_visits;
    integer n_critical_visits;
    reg [1:0] prev_state;
    integer cycle_counter;

    // Monitor state transitions
    always @(posedge clk) begin
        if (!rst_n) begin
            prev_state      <= `IPM_SLEEP;
            monitor_dwell   <= 0;
            warning_dwell   <= 0;
            critical_dwell  <= 0;
            n_transitions   <= 0;
        end else begin
            // Count current-state dwell
            case (ipm_state)
                `IPM_MONITOR:  monitor_dwell  <= monitor_dwell  + 1;
                `IPM_WARNING:  warning_dwell  <= warning_dwell  + 1;
                `IPM_CRITICAL: critical_dwell <= critical_dwell + 1;
                default: ;
            endcase

            // Detect transition
            if (ipm_state !== prev_state) begin
                n_transitions <= n_transitions + 1;
                prev_state    <= ipm_state;
            end
        end
    end

    // Track per-trace accumulated totals
    integer trace_num;
    integer total_cycles;

    // ---- Standard chip initialisation ----
    task chip_init;
        begin
            $display("\n  [Init] Programming register file...");
            // Weights: sum = 13+13+13+13+12 = 64
            reg_write(8'h10, 8'd13); reg_write(8'h11, 8'd13);
            reg_write(8'h12, 8'd13); reg_write(8'h13, 8'd13);
            reg_write(8'h14, 8'd12);
            // CSA shift = 6 (divide by 64)
            reg_write(8'h19, 8'd6);
            // Fusion pattern: all Don't Care
            reg_write(8'h55, 8'h00); reg_write(8'h56, 8'h00);
            // DECDE shift factors = 2
            reg_write(8'h20, 8'd2); reg_write(8'h21, 8'd2);
            reg_write(8'h22, 8'd2); reg_write(8'h23, 8'd2);
            reg_write(8'h24, 8'd2);
            // Fusion window=4, vote_threshold=2
            reg_write(8'h51, 8'd4); reg_write(8'h52, 8'd2);
            // Decision tree thresholds
            reg_write(8'h60, 8'd10);  // T0: stress_score
            reg_write(8'h61, 8'd1);   // T1: fusion_score
            reg_write(8'h62, 8'd80);  // T2: moisture
            reg_write(8'h63, 8'd120); // T3: leaf_temp
            reg_write(8'h64, 8'd90);  // T4: humidity
            reg_write(8'h65, 8'd120); // T5: air_temp
            reg_write(8'h66, 8'd130); // T6: light
            // SA-ADC thresholds
            reg_write(8'h80, 8'd100); reg_write(8'h81, 8'd180);
            reg_write(8'h82, 8'd120); reg_write(8'h83, 8'd200);
            reg_write(8'h84, 8'd110); reg_write(8'h85, 8'd210);
            reg_write(8'h86, 8'd115); reg_write(8'h87, 8'd220);
            reg_write(8'h88, 8'd130); reg_write(8'h89, 8'd230);
            reg_write(8'h8A, 8'd50);  reg_write(8'h8B, 8'd120);
            // Wake FSM to MONITOR
            @(posedge clk); wake_timer = 1;
            @(posedge clk); wake_timer = 0;
            repeat(3) @(posedge clk);
        end
    endtask

    // ---- Run one trace scenario and print report ----
    task run_trace;
        input [64*8-1:0] trace_name;
        input integer    n_samples;
        // sensor data passed as individual 8-bit values per sample pair
        // We model the three traces inline in the initial block below
        begin
        end
    endtask

    // =========================================================
    // Pre-loaded trace data arrays (correlated_stress_01/02/03)
    // =========================================================
    reg [7:0] t01_m  [0:199];
    reg [7:0] t01_lt [0:199];
    reg [7:0] t01_h  [0:199];
    reg [7:0] t01_at [0:199];
    reg [7:0] t01_l  [0:199];

    reg [7:0] t02_m  [0:199];
    reg [7:0] t02_lt [0:199];
    reg [7:0] t02_h  [0:199];
    reg [7:0] t02_at [0:199];
    reg [7:0] t02_l  [0:199];

    reg [7:0] t03_m  [0:199];
    reg [7:0] t03_lt [0:199];
    reg [7:0] t03_h  [0:199];
    reg [7:0] t03_at [0:199];
    reg [7:0] t03_l  [0:199];

    integer si;

    // Fill arrays using Verilog $readmemh or inline generation
    // (Inline generation mirrors generate_traces.py math exactly)
    task preload_traces;
        integer c;
        integer v;
        begin
            for (c = 0; c < 200; c = c + 1) begin
                // --- Trace 01: Water Stress ---
                v = 140 - c; if (v < 60) v = 60;
                t01_m [c] = v[7:0];
                v = 100 + c/2; if (v > 145) v = 145;
                t01_lt[c] = v[7:0];
                v = 120 - c/10;
                t01_h [c] = v[7:0];
                t01_at[c] = 8'd105;
                t01_l [c] = 8'd120;

                // --- Trace 02: Thermal Stress ---
                v = 140 - c/3; if (v < 100) v = 100;
                t02_m [c] = v[7:0];
                v = 100 + c;   if (v > 200) v = 200;
                t02_lt[c] = v[7:0];
                v = 120 - c/2; if (v < 70)  v = 70;
                t02_h [c] = v[7:0];
                v = 100 + c;   if (v > 200) v = 200;
                t02_at[c] = v[7:0];
                t02_l [c] = 8'd130;

                // --- Trace 03: Multi-Factor Staggered ---
                v = (c < 10) ? 140 : (140 - (c-10)*2); if (v < 50) v = 50;
                t03_m [c] = v[7:0];
                v = (c < 25) ? 120 : (120 - (c-25)*2); if (v < 60) v = 60;
                t03_h [c] = v[7:0];
                v = (c < 50) ? 120 : (120 + (c-50)*2); if (v > 220) v = 220;
                t03_l [c] = v[7:0];
                v = 100 + c/5;
                t03_lt[c] = v[7:0];
                t03_at[c] = 8'd105;
            end
        end
    endtask

    // ---- Dwell timer for a single trace run ---
    integer mon_start, warn_start, crit_start;
    integer cyc;
    integer warn_dwell_cur;
    integer crit_dwell_cur;

    task run_and_report;
        input [8*32-1:0] label;
        input integer n;
        begin
            // Reset counters
            monitor_dwell  = 0;
            warning_dwell  = 0;
            critical_dwell = 0;
            n_transitions  = 0;
            n_warning_visits  = 0;
            n_critical_visits = 0;
            total_warning_dwell  = 0;
            total_critical_dwell = 0;
            warn_dwell_cur = 0;
            crit_dwell_cur = 0;
            prev_state = `IPM_MONITOR;

            $display("\n========================================");
            $display(" Dwell-Time Report: %0s", label);
            $display("========================================");
            $display(" Cycle |  State  | D2 | Sev");
            $display("-------|---------|----|---------");

            for (cyc = 0; cyc < n; cyc = cyc + 1) begin
                case (label)
                    "correlated_stress_01": push_sample(t01_m[cyc], t01_lt[cyc], t01_h[cyc], t01_at[cyc], t01_l[cyc]);
                    "correlated_stress_02": push_sample(t02_m[cyc], t02_lt[cyc], t02_h[cyc], t02_at[cyc], t02_l[cyc]);
                    "correlated_stress_03": push_sample(t03_m[cyc], t03_lt[cyc], t03_h[cyc], t03_at[cyc], t03_l[cyc]);
                    default: push_sample(8'd120, 8'd100, 8'd110, 8'd105, 8'd115);
                endcase

                // Track WARNING visit dwell
                if (ipm_state == `IPM_WARNING) begin
                    warn_dwell_cur = warn_dwell_cur + 1;
                end else if (warn_dwell_cur > 0) begin
                    total_warning_dwell = total_warning_dwell + warn_dwell_cur;
                    n_warning_visits    = n_warning_visits + 1;
                    warn_dwell_cur = 0;
                end

                // Track CRITICAL visit dwell
                if (ipm_state == `IPM_CRITICAL) begin
                    crit_dwell_cur = crit_dwell_cur + 1;
                end else if (crit_dwell_cur > 0) begin
                    total_critical_dwell = total_critical_dwell + crit_dwell_cur;
                    n_critical_visits    = n_critical_visits + 1;
                    crit_dwell_cur = 0;
                end

                if (cyc % 20 == 0 || ipm_state !== prev_state) begin
                    case(ipm_state)
                        `IPM_SLEEP:    $display(" %5d | SLEEP   |  %b | sev=%2b", cyc, domain2_pwr_en, leaf_output[3:2]);
                        `IPM_MONITOR:  $display(" %5d | MONITOR |  %b | sev=%2b", cyc, domain2_pwr_en, leaf_output[3:2]);
                        `IPM_WARNING:  $display(" %5d | WARNING |  %b | sev=%2b", cyc, domain2_pwr_en, leaf_output[3:2]);
                        `IPM_CRITICAL: $display(" %5d | CRITICAL|  %b | sev=%2b", cyc, domain2_pwr_en, leaf_output[3:2]);
                    endcase
                end

                prev_state = ipm_state;
            end

            // Flush any open warning/critical at end
            if (warn_dwell_cur > 0) begin
                total_warning_dwell = total_warning_dwell + warn_dwell_cur;
                n_warning_visits    = n_warning_visits + 1;
            end
            if (crit_dwell_cur > 0) begin
                total_critical_dwell = total_critical_dwell + crit_dwell_cur;
                n_critical_visits    = n_critical_visits + 1;
            end

            $display("\n----------------------------------------");
            $display(" Summary: %0s", label);
            $display("----------------------------------------");
            $display("  Total samples        : %0d", n);
            $display("  MONITOR dwell (cyc)  : %0d", monitor_dwell);
            $display("  WARNING  dwell (cyc) : %0d", warning_dwell);
            $display("  CRITICAL dwell (cyc) : %0d", critical_dwell);
            $display("  WARNING  visits      : %0d", n_warning_visits);
            $display("  CRITICAL visits      : %0d", n_critical_visits);
            if (n_warning_visits > 0)
                $display("  Avg WARNING  dwell   : %0d cyc/visit",
                         total_warning_dwell / n_warning_visits);
            else
                $display("  Avg WARNING  dwell   : N/A (no visits)");
            if (n_critical_visits > 0)
                $display("  Avg CRITICAL dwell   : %0d cyc/visit",
                         total_critical_dwell / n_critical_visits);
            else
                $display("  Avg CRITICAL dwell   : N/A (no visits)");
            $display("  State transitions    : %0d", n_transitions);
        end
    endtask

    // =========================================================
    // MAIN
    // =========================================================
    initial begin
        $dumpfile("tb_dwell_report.vcd");
        $dumpvars(0, uut.ipm_state);
        $dumpvars(0, uut.stress_event);
        $dumpvars(0, uut.domain2_pwr_en);
        $dumpvars(0, uut.leaf_output_iso);

        clk = 0; rst_n = 0;
        m_addr = 0; m_wdata = 0; m_we = 0; m_re = 0;
        sample_valid = 0; wake_timer = 0;
        moisture = 120; leaf_temp = 100; humidity = 110;
        air_temp = 105; light = 115; battery = 200;

        #100; rst_n = 1; #20;

        preload_traces();
        chip_init();

        $display("\n");
        $display("####################################################");
        $display("# AgriSense-IPMS Dwell-Time Report — RTL v1.0      ");
        $display("# Validates: Contribution #3 (Hierarchical Wake Pipeline)");
        $display("####################################################");

        run_and_report("correlated_stress_01", 200);
        chip_init();

        run_and_report("correlated_stress_02", 200);
        chip_init();

        run_and_report("correlated_stress_03", 200);

        $display("\n\n=== ALL DWELL-TIME EXPERIMENTS COMPLETE ===\n");
        $finish;
    end

endmodule
