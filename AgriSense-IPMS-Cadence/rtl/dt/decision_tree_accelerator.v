module decision_tree_accelerator(
    // 5 Sensors
    input wire [7:0] moisture,
    input wire [7:0] leaf_temp,
    input wire [7:0] humidity,
    input wire [7:0] air_temp,
    input wire [7:0] light,
    
    // Scores
    input wire [7:0] stress_score,
    input wire [2:0] fusion_score,
    
    // Control
    input wire stress_event,
    
    // 7 Programmable Thresholds
    input wire [7:0] t0, // Stress Score
    input wire [7:0] t1, // Fusion Score
    input wire [7:0] t2, // Moisture
    input wire [7:0] t3, // LeafTemp
    input wire [7:0] t4, // Humidity
    input wire [7:0] t5, // AirTemp
    input wire [7:0] t6, // Light

    // Output: {severity[1:0], type[1:0]}
    output reg [3:0] leaf_output
);

    // Leaf Outputs Encoding: {severity[1:0], type[1:0]}
    // Severity: 00=Normal, 01=Warning/Low, 10=Warning/Moderate, 11=Critical
    // Type:     00=Generic, 01=Water, 10=Temperature, 11=Multi-Factor
    localparam NORMAL              = 4'b0000;
    localparam LOW_STRESS          = 4'b0100;
    localparam MODERATE_STRESS     = 4'b1000;
    localparam HIGH_STRESS         = 4'b1100;
    localparam CRITICAL_STRESS     = 4'b1100;
    localparam WATER_DOMINANT      = 4'b1101;
    localparam TEMP_DOMINANT       = 4'b1110;
    localparam MULTI_FACTOR_EVENT  = 4'b1111;

    // Node evaluations
    // Tree topology:
    //         Node0 (stress_score)
    //         /                  \
    //      Node1 (fusion_score)  Node2 (moisture)
    //      /      \              /      \
    //   Node3     Node4       Node5     Node6
    // (leaf_temp)(humidity) (air_temp)  (light)
    
    wire n0_go_left = (stress_score < t0);
    wire n1_go_left = ({5'b00000, fusion_score} < t1);
    wire n2_go_left = (moisture < t2);
    wire n3_go_left = (leaf_temp < t3);
    wire n4_go_left = (humidity < t4);
    wire n5_go_left = (air_temp < t5);
    wire n6_go_left = (light < t6);

    always @(*) begin
        if (!stress_event) begin
            leaf_output = NORMAL;
        end else begin
            if (n0_go_left) begin
                if (n1_go_left) begin
                    if (n3_go_left) leaf_output = NORMAL;
                    else            leaf_output = LOW_STRESS;
                end else begin
                    if (n4_go_left) leaf_output = MODERATE_STRESS;
                    else            leaf_output = HIGH_STRESS;
                end
            end else begin
                if (n2_go_left) begin
                    if (n5_go_left) leaf_output = WATER_DOMINANT;
                    else            leaf_output = TEMP_DOMINANT;
                end else begin
                    if (n6_go_left) leaf_output = CRITICAL_STRESS;
                    else            leaf_output = MULTI_FACTOR_EVENT;
                end
            end
        end
    end
endmodule
