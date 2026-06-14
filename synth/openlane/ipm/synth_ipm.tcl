# =============================================================
# OpenROAD / Yosys Synthesis Wrapper
# Block: ipm_fsm
# PDK: sky130hd
# =============================================================

set DESIGN_NAME   "ipm_fsm"
set RTL_FILES     [list \
    "../../../rtl/ipm/ipm_fsm.v"
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
