module power_controller (
    // Domain 2 Raw Outputs
    input  wire [7:0] stress_score_in,
    input  wire [3:0] leaf_output_in,
    input  wire       domain2_pwr_en,

    // Isolated Outputs going to Always-On Domain (Register File, IPM FSM)
    output wire [7:0] stress_score_iso,
    output wire [3:0] leaf_output_iso
);

    // Isolate stress_score when Domain 2 is powered down
    isolation_cell #(.WIDTH(8)) iso_stress_score (
        .in_val(stress_score_in),
        .isolate(!domain2_pwr_en),
        .out_val(stress_score_iso)
    );

    // Isolate leaf_output when Domain 2 is powered down
    isolation_cell #(.WIDTH(4)) iso_leaf_output (
        .in_val(leaf_output_in),
        .isolate(!domain2_pwr_en),
        .out_val(leaf_output_iso)
    );

endmodule
