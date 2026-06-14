# =============================================================
# OpenROAD / Yosys Synthesis Wrapper
# Block: register_file + reg_bus_interconnect
# PDK: sky130hd
# =============================================================

set DESIGN_NAME   "register_file"
set RTL_FILES     [list \
    "../../../rtl/common/agrisense_defs.vh" \
    "../../../rtl/common/reg_bus_interconnect.v" \
    "../../../rtl/common/register_file.v"
]
set CLOCK_PORT    "clk"
set CLOCK_PERIOD  10.0

foreach f $RTL_FILES { read_verilog $f }
synth_design -top $DESIGN_NAME -flatten_hierarchy rebuilt

create_clock -name clk -period $CLOCK_PERIOD [get_ports $CLOCK_PORT]

report_checks -path_delay max
report_checks -path_delay min
report_power
report_design_area
