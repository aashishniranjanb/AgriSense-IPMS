`include "agrisense_defs.vh"

module ipm_fsm(
    input  wire       clk,
    input  wire       rst_n,

    input  wire       wake_timer,
    input  wire       stress_event,
    input  wire [1:0] leaf_output,

    output reg  [1:0] state,

    output reg        domain2_pwr_en,
    output reg        domain3_pwr_en,

    output reg        sensor_en,
    output reg        decde_en,
    output reg        csa_en,
    output reg        dtree_en,
    output reg        comm_en
);

    reg [1:0] next_state;

    // Sequential State Register
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            state <= `IPM_SLEEP;
        else
            state <= next_state;
    end

    // Next-State Logic
    always @(*) begin
        next_state = state; // Default hold

        case(state)
            `IPM_SLEEP: begin
                if(wake_timer)
                    next_state = `IPM_MONITOR;
            end
            
            `IPM_MONITOR: begin
                if(stress_event)
                    next_state = `IPM_WARNING;
            end
            
            `IPM_WARNING: begin
                if(leaf_output == 2'b10) // DTree says CRITICAL
                    next_state = `IPM_CRITICAL;
                else if(leaf_output == 2'b00) // DTree says NORMAL
                    next_state = `IPM_MONITOR;
            end
            
            `IPM_CRITICAL: begin
                if(leaf_output != 2'b10) // DTree no longer says CRITICAL
                    next_state = `IPM_WARNING;
            end
            
            default: next_state = `IPM_SLEEP;
        endcase
    end

    // Output Decode Logic
    always @(*) begin
        // Defaults
        sensor_en      = 1'b0;
        decde_en       = 1'b0;
        csa_en         = 1'b0;
        dtree_en       = 1'b0;
        comm_en        = 1'b0;
        domain2_pwr_en = 1'b0;
        domain3_pwr_en = 1'b0;

        case(state)
            `IPM_SLEEP: begin
                // All blocks off. Only always-on timers and FSM active.
            end

            `IPM_MONITOR: begin
                sensor_en = 1'b1;
                decde_en  = 1'b1;
            end

            `IPM_WARNING: begin
                sensor_en = 1'b1;
                decde_en  = 1'b1;

                domain2_pwr_en = 1'b1;
                
                csa_en    = 1'b1;
                dtree_en  = 1'b1;
            end

            `IPM_CRITICAL: begin
                sensor_en = 1'b1;
                decde_en  = 1'b1;

                domain2_pwr_en = 1'b1;
                domain3_pwr_en = 1'b1;

                csa_en    = 1'b1;
                dtree_en  = 1'b1;
                comm_en   = 1'b1;
            end
        endcase
    end

endmodule
