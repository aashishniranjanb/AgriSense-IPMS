module crop_stress_accelerator(
    input wire [7:0] moisture,
    input wire [7:0] leaf_temp,
    input wire [7:0] humidity,
    input wire [7:0] air_temp,
    input wire [7:0] light,
    
    input wire [7:0] w_moisture,
    input wire [7:0] w_leaftemp,
    input wire [7:0] w_humidity,
    input wire [7:0] w_airtemp,
    input wire [7:0] w_light,
    
    input wire [3:0] shift_factor,
    
    output wire [7:0] stress_score
);

    wire [15:0] p_moisture;
    wire [15:0] p_leaftemp;
    wire [15:0] p_humidity;
    wire [15:0] p_airtemp;
    wire [15:0] p_light;

    weighted_sum ws_moisture (
        .sensor_value(moisture),
        .weight(w_moisture),
        .product(p_moisture)
    );

    weighted_sum ws_leaftemp (
        .sensor_value(leaf_temp),
        .weight(w_leaftemp),
        .product(p_leaftemp)
    );

    weighted_sum ws_humidity (
        .sensor_value(humidity),
        .weight(w_humidity),
        .product(p_humidity)
    );

    weighted_sum ws_airtemp (
        .sensor_value(air_temp),
        .weight(w_airtemp),
        .product(p_airtemp)
    );

    weighted_sum ws_light (
        .sensor_value(light),
        .weight(w_light),
        .product(p_light)
    );

    wire [18:0] weighted_sum_val;
    assign weighted_sum_val = {3'b0, p_moisture} + {3'b0, p_leaftemp} + {3'b0, p_humidity} + {3'b0, p_airtemp} + {3'b0, p_light};

    // Instantiate range-check/normalization block
    normalization_unit norm_inst (
        .weighted_sum_val(weighted_sum_val),
        .shift_factor(shift_factor),
        .stress_score(stress_score)
    );

endmodule
