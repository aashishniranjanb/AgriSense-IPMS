# =============================================================
# OpenROAD Synthesis — sa_adc_controller
# Block: Stress-Aware ADC Controller (Domain 2)
# PDK: sky130
# Flow: Yosys → OpenROAD → GDSII
# =============================================================

# Paths
set DESIGN_NAME    "sa_adc_controller"
set RTL_FILES      [list \
    "../../../rtl/sa_adc/sa_adc_controller.v"
]
set CLOCK_PORT     ""          ;# Purely combinational block
set CLOCK_PERIOD   10.0        ;# 100 MHz reference (timing only)
set TARGET_DENSITY 0.65

# ------- Synthesis (Yosys via OpenROAD synth_design) -------
read_verilog {*}$RTL_FILES
synth_design -top $DESIGN_NAME -flatten_hierarchy rebuilt -mode out_of_context

# ------- Timing -------
create_clock -name clk -period $CLOCK_PERIOD [get_ports clk]

# ------- Reports -------
report_checks -path_delay max
report_checks -path_delay min
report_power
report_design_area
