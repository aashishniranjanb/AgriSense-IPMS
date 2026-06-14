module reg_bus_interconnect (
    // Master Interface
    input  wire [7:0] m_addr,
    input  wire [7:0] m_wdata,
    input  wire       m_we,
    input  wire       m_re,
    output wire [7:0] m_rdata,

    // Slave Interface (Register File)
    output wire [7:0] s_addr,
    output wire [7:0] s_wdata,
    output wire       s_we,
    output wire       s_re,
    input  wire [7:0] s_rdata
);

    // Direct 1-to-1 pass-through routing for the Register File.
    // Extremely simple interface as defined in Phase 1 constraints.
    // (No AHB, no APB, no AXI).

    assign s_addr  = m_addr;
    assign s_wdata = m_wdata;
    assign s_we    = m_we;
    assign s_re    = m_re;
    
    assign m_rdata = s_rdata;

endmodule
