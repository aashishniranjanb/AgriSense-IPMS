# =============================================================
# OpenROAD / Yosys Synthesis Wrapper
# Block: agrisense_ipms_top  (FULL CHIP)
# PDK: sky130hd
# =============================================================

set DESIGN_NAME   "agrisense_ipms_top"
set CLOCK_PORT    "clk"
set CLOCK_PERIOD  10.0   ;# 100 MHz

set RTL_FILES [list \
    "../../rtl/common/agrisense_defs.vh" \
    "../../rtl/common/isolation_cell.v" \
    "../../rtl/common/reg_bus_interconnect.v" \
    "../../rtl/common/register_file.v" \
    "../../rtl/common/synchronizer.v" \
    "../../rtl/decde/ema_filter.v" \
    "../../rtl/decde/crossover_detector.v" \
    "../../rtl/decde/decde_channel.v" \
    "../../rtl/decde/fusion_unit.v" \
    "../../rtl/csa/weighted_sum.v" \
    "../../rtl/csa/normalization_unit.v" \
    "../../rtl/csa/crop_stress_accelerator.v" \
    "../../rtl/dt/decision_tree_accelerator.v" \
    "../../rtl/ipm/ipm_fsm.v" \
    "../../rtl/ipm/power_controller.v" \
    "../../rtl/ipm/wake_controller.v" \
    "../../rtl/sa_adc/sa_adc_controller.v" \
    "../../rtl/top/agrisense_ipms_top.v" \
]

foreach f $RTL_FILES { read_verilog $f }

synth_design -top $DESIGN_NAME -flatten_hierarchy rebuilt

create_clock -name clk -period $CLOCK_PERIOD [get_ports $CLOCK_PORT]

# ------- Timing -------
report_checks -path_delay max -fields {slew cap input nets fanout} -format full_clock_expanded
report_checks -path_delay min -fields {slew cap input nets fanout} -format full_clock_expanded
report_check_types -max_slew -max_cap -max_fanout -violators
report_clock_skew

# ------- Power -------
report_power

# ------- Area -------
report_design_area

# ------- Cell Count -------
report_cell_usage
