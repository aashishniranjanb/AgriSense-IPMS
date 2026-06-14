# =============================================================
# OpenROAD / Yosys Synthesis Wrapper
# Block: decision_tree_accelerator
# PDK: sky130hd
# =============================================================

set DESIGN_NAME   "decision_tree_accelerator"
set RTL_FILES     [list \
    "../../../rtl/dt/decision_tree_accelerator.v"
]
set CLOCK_PORT    ""
set CLOCK_PERIOD  10.0

read_verilog {*}$RTL_FILES
synth_design -top $DESIGN_NAME -flatten_hierarchy rebuilt -mode out_of_context

report_checks -path_delay max
report_power
report_design_area
