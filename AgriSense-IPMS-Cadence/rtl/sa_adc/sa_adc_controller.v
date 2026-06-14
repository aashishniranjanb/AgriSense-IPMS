module sa_adc_controller (
    input wire [7:0] stress_score,
    input wire [2:0] fusion_score,
    input wire [7:0] battery_level,

    // 10 thresholds (T1 and T2 per channel)
    input wire [7:0] moisture_t1,
    input wire [7:0] moisture_t2,
    input wire [7:0] leaf_t1,
    input wire [7:0] leaf_t2,
    input wire [7:0] humidity_t1,
    input wire [7:0] humidity_t2,
    input wire [7:0] air_t1,
    input wire [7:0] air_t2,
    input wire [7:0] light_t1,
    input wire [7:0] light_t2,

    // Battery thresholds
    input wire [7:0] b_crit,
    input wire [7:0] b_low,

    // 10-bit resolution vector output (2 bits per channel)
    output wire [9:0] adc_mode_vector
);

    wire [1:0] mode_moisture;
    wire [1:0] mode_leaftemp;
    wire [1:0] mode_humidity;
    wire [1:0] mode_airtemp;
    wire [1:0] mode_light;

    function [1:0] get_channel_mode;
        input [7:0] score;
        input [2:0] f_score;
        input [7:0] t1;
        input [7:0] t2;
        input [7:0] batt;
        input [7:0] bcrit;
        input [7:0] blow;
        reg [1:0] base_mode;
        reg [1:0] escalated_mode;
        begin
            // 1. Compute Base Mode based on stress_score vs channel thresholds
            if (score < t1)
                base_mode = 2'b00; // 8-bit
            else if (score < t2)
                base_mode = 2'b01; // 10-bit
            else
                base_mode = 2'b10; // 12-bit

            // 2. Context Escalation: if multiple channels show trends, escalate Warning to Critical
            if (f_score >= 3'd2 && base_mode == 2'b01)
                escalated_mode = 2'b10;
            else
                escalated_mode = base_mode;

            // 3. Battery overrides
            if (batt < bcrit)
                get_channel_mode = 2'b00; // Force 8-bit (Critical Power Saving)
            else if (batt < blow)
                get_channel_mode = (escalated_mode > 2'b01) ? 2'b01 : escalated_mode; // Cap at 10-bit (Low Power Saving)
            else
                get_channel_mode = escalated_mode; // Nominal battery: follow adapted mode
        end
    endfunction

    assign mode_moisture = get_channel_mode(stress_score, fusion_score, moisture_t1, moisture_t2, battery_level, b_crit, b_low);
    assign mode_leaftemp = get_channel_mode(stress_score, fusion_score, leaf_t1, leaf_t2, battery_level, b_crit, b_low);
    assign mode_humidity = get_channel_mode(stress_score, fusion_score, humidity_t1, humidity_t2, battery_level, b_crit, b_low);
    assign mode_airtemp  = get_channel_mode(stress_score, fusion_score, air_t1, air_t2, battery_level, b_crit, b_low);
    assign mode_light    = get_channel_mode(stress_score, fusion_score, light_t1, light_t2, battery_level, b_crit, b_low);

    // Pack into a 10-bit vector
    // Channel order: moisture [1:0], leaf_temp [3:2], humidity [5:4], air_temp [7:6], light [9:8]
    assign adc_mode_vector = {mode_light, mode_airtemp, mode_humidity, mode_leaftemp, mode_moisture};

endmodule
