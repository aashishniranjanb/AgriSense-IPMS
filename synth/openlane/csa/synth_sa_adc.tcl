# =============================================================
# OpenROAD / Yosys Synthesis Wrapper
# Block: crop_stress_accelerator + weighted_sum + normalization_unit
# PDK: sky130hd
# =============================================================

set DESIGN_NAME   "crop_stress_accelerator"
set RTL_FILES     [list \
    "../../../rtl/csa/weighted_sum.v" \
    "../../../rtl/csa/normalization_unit.v" \
    "../../../rtl/csa/crop_stress_accelerator.v"
]
set CLOCK_PORT    ""
set CLOCK_PERIOD  10.0

read_verilog {*}$RTL_FILES
synth_design -top $DESIGN_NAME -flatten_hierarchy rebuilt -mode out_of_context

report_checks -path_delay max
report_power
report_design_area
