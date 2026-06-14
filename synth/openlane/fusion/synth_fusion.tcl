# =============================================================
# OpenROAD / Yosys Synthesis Wrapper
# Block: fusion_unit
# PDK: sky130hd
# =============================================================

set DESIGN_NAME   "fusion_unit"
set RTL_FILES     [list \
    "../../../rtl/decde/fusion_unit.v"
]
set CLOCK_PORT    "clk"
set CLOCK_PERIOD  10.0

read_verilog {*}$RTL_FILES
synth_design -top $DESIGN_NAME -flatten_hierarchy rebuilt

create_clock -name clk -period $CLOCK_PERIOD [get_ports $CLOCK_PORT]

report_checks -path_delay max
report_checks -path_delay min
report_power
report_design_area
