`include "agrisense_defs.vh"

module register_file(
    input  wire       clk,
    input  wire       rst_n,

    input  wire [7:0] addr,
    input  wire [7:0] wdata,

    input  wire       we,
    input  wire       re,

    output reg  [7:0] rdata,

    // --- Configuration Outputs (Always-On) ---
    // CSA Weights
    output wire [7:0] w_moisture,
    output wire [7:0] w_leaftemp,
    output wire [7:0] w_humidity,
    output wire [7:0] w_airtemp,
    output wire [7:0] w_light,

    // DECDE Shift Factors
    output wire [2:0] shift_factor_0,
    output wire [2:0] shift_factor_1,
    output wire [2:0] shift_factor_2,
    output wire [2:0] shift_factor_3,
    output wire [2:0] shift_factor_4,

    // Fusion
    output wire [2:0] vote_threshold,
    output wire [7:0] window_size,
    output wire [3:0] normalization_shift,

    // Decision Tree Thresholds
    output wire [7:0] t0,
    output wire [7:0] t1,
    output wire [7:0] t2,
    output wire [7:0] t3,
    output wire [7:0] t4,
    output wire [7:0] t5,
    output wire [7:0] t6,

    // SA-ADC Thresholds
    output wire [7:0] moisture_t1,
    output wire [7:0] moisture_t2,
    output wire [7:0] leaf_t1,
    output wire [7:0] leaf_t2,
    output wire [7:0] humidity_t1,
    output wire [7:0] humidity_t2,
    output wire [7:0] air_t1,
    output wire [7:0] air_t2,
    output wire [7:0] light_t1,
    output wire [7:0] light_t2,
    output wire [7:0] b_crit,
    output wire [7:0] b_low,
    output wire [9:0] fusion_pattern,
    output wire       weights_valid,

    // --- Status Inputs (from internal design blocks) ---
    input wire [7:0] status_moisture,
    input wire [7:0] status_leaftemp,
    input wire [7:0] status_humidity,
    input wire [7:0] status_airtemp,
    input wire [7:0] status_light,
    input wire [7:0] status_battery,

    input wire [7:0] status_stress_score,
    input wire [4:0] status_cross_flags,
    input wire [2:0] status_fusion_score,
    input wire       status_stress_event,
    input wire [3:0] status_leaf_output,
    
    input wire [7:0] status_adc_mode_lsb,
    input wire [1:0] status_adc_mode_msb,
    
    input wire [1:0] status_ipm_state,
    input wire [7:0] status_ipm_enables
);

    // 256 x 8-bit registers (Always-On Domain Storage)
    reg [7:0] reg_mem [0:255];

    integer i;

    // Write Logic with critical RESET fix
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            // LEVEL 3 CHECK: All registers known after reset. No X values.
            for(i=0; i<256; i=i+1) begin
                reg_mem[i] <= 8'h00;
            end
            reg_mem[8'h19] <= 8'd6; // default shift of 6 (div 64)
        end else if(we) begin
            reg_mem[addr] <= wdata;
        end
    end

    // Read Logic with Real-Time Status Bypass (latch-free: default driven first)
    always @(*) begin
        rdata = 8'h00; // default: drive to 0 — prevents latch inference
        if(re) begin
            case(addr)
                8'h04: rdata = status_moisture;
                8'h05: rdata = status_leaftemp;
                8'h06: rdata = status_humidity;
                8'h07: rdata = status_airtemp;
                8'h08: rdata = status_light;
                8'h09: rdata = status_battery;
                
                8'h18: rdata = status_stress_score;
                8'h1A: rdata = {7'b0000000, weights_valid};
                
                8'h50: rdata = {3'b000, status_cross_flags};
                8'h53: rdata = {5'b00000, status_fusion_score};
                8'h54: rdata = {7'b0000000, status_stress_event};
                
                8'h70: rdata = {status_leaf_output[1:0], 4'b0000, status_leaf_output[3:2]};
                
                8'h8C: rdata = status_adc_mode_lsb;
                8'h8D: rdata = {6'b000000, status_adc_mode_msb};
                
                8'hA0: rdata = {6'b000000, status_ipm_state};
                8'hA1: rdata = status_ipm_enables;
                
                default: rdata = reg_mem[addr];
            endcase
        end
    end

    // Parallel Assignments for Combinational Blocks
    assign w_moisture     = reg_mem[8'h10];
    assign w_leaftemp     = reg_mem[8'h11];
    assign w_humidity     = reg_mem[8'h12];
    assign w_airtemp      = reg_mem[8'h13];
    assign w_light        = reg_mem[8'h14];

    assign shift_factor_0 = reg_mem[8'h20][2:0];
    assign shift_factor_1 = reg_mem[8'h21][2:0];
    assign shift_factor_2 = reg_mem[8'h22][2:0];
    assign shift_factor_3 = reg_mem[8'h23][2:0];
    assign shift_factor_4 = reg_mem[8'h24][2:0];

    assign vote_threshold = reg_mem[8'h52][2:0];
    assign window_size   = reg_mem[8'h51];
    assign normalization_shift = reg_mem[8'h19][3:0];

    assign t0 = reg_mem[8'h60];
    assign t1 = reg_mem[8'h61];
    assign t2 = reg_mem[8'h62];
    assign t3 = reg_mem[8'h63];
    assign t4 = reg_mem[8'h64];
    assign t5 = reg_mem[8'h65];
    assign t6 = reg_mem[8'h66];

    assign moisture_t1   = reg_mem[8'h80];
    assign moisture_t2   = reg_mem[8'h81];
    assign leaf_t1       = reg_mem[8'h82];
    assign leaf_t2       = reg_mem[8'h83];
    assign humidity_t1   = reg_mem[8'h84];
    assign humidity_t2   = reg_mem[8'h85];
    assign air_t1        = reg_mem[8'h86];
    assign air_t2        = reg_mem[8'h87];
    assign light_t1      = reg_mem[8'h88];
    assign light_t2      = reg_mem[8'h89];
    assign b_crit        = reg_mem[8'h8A];
    assign b_low         = reg_mem[8'h8B];

    // Weight validity checker
    wire [10:0] weight_sum = w_moisture + w_leaftemp + w_humidity + w_airtemp + w_light;
    assign weights_valid = (weight_sum == 11'd64);

    // Fusion pattern
    assign fusion_pattern = {reg_mem[8'h56][1:0], reg_mem[8'h55]};

endmodule
