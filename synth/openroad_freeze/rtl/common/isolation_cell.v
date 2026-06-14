module isolation_cell #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] in_val,
    input  wire             isolate,
    output wire [WIDTH-1:0] out_val
);

    // Force output to zero when isolation is active.
    assign out_val = isolate ? {WIDTH{1'b0}} : in_val;

endmodule
