# ==============================================================================
# OpenLane v1 Configuration for AgriSense-IPMS Top Module
# Design: agrisense_ipms_top
# PDK: sky130A (SkyWater 130nm standard cells)
# ==============================================================================

# Design Name
set ::env(DESIGN_NAME) "agrisense_ipms_top"

# Resolve Project Root path relative to this script
set PROJ_ROOT [file normalize [file join [file dirname [info script]] "../../.."]]

# Source Verilog RTL Files
set ::env(VERILOG_FILES) [list \
    "$PROJ_ROOT/rtl/common/isolation_cell.v" \
    "$PROJ_ROOT/rtl/common/reg_bus_interconnect.v" \
    "$PROJ_ROOT/rtl/common/register_file.v" \
    "$PROJ_ROOT/rtl/common/synchronizer.v" \
    "$PROJ_ROOT/rtl/decde/ema_filter.v" \
    "$PROJ_ROOT/rtl/decde/crossover_detector.v" \
    "$PROJ_ROOT/rtl/decde/decde_channel.v" \
    "$PROJ_ROOT/rtl/decde/fusion_unit.v" \
    "$PROJ_ROOT/rtl/csa/weighted_sum.v" \
    "$PROJ_ROOT/rtl/csa/normalization_unit.v" \
    "$PROJ_ROOT/rtl/csa/crop_stress_accelerator.v" \
    "$PROJ_ROOT/rtl/dt/decision_tree_accelerator.v" \
    "$PROJ_ROOT/rtl/ipm/ipm_fsm.v" \
    "$PROJ_ROOT/rtl/ipm/power_controller.v" \
    "$PROJ_ROOT/rtl/ipm/wake_controller.v" \
    "$PROJ_ROOT/rtl/sa_adc/sa_adc_controller.v" \
    "$PROJ_ROOT/rtl/top/agrisense_ipms_top.v" \
]

# Include directories
set ::env(SYNTH_INCLUDES) [list "$PROJ_ROOT/rtl/common"]

# Clock Configuration
set ::env(CLOCK_PORT) "clk"
# Relaxed clock period: 50 ns (20 MHz) for the initial layout pass to prevent
# routing congestion and Magic DRC violations, sweeping post-PnR for Fmax.
set ::env(CLOCK_PERIOD) "50.0"

# Target PDK & Library
set ::env(PDK) "sky130A"
set ::env(STD_CELL_LIBRARY) "sky130_fd_sc_hd"

# Synthesis Configuration
# AREA 0 represents area-optimized strategy consistent with low-power framing.
set ::env(SYNTH_STRATEGY) "AREA 0"

# Floorplan Configuration
# Set conservatively to 35% utilization to handle IO pin pitch limits around
# the small core perimeter (macro-level pin limits).
set ::env(FP_CORE_UTIL) 35
set ::env(PL_TARGET_DENSITY) 0.35

# Power and Ground Nets
set ::env(VDD_NETS) [list {vccd1}]
set ::env(GND_NETS) [list {vssd1}]

# PDN Tuning for Small Die
# Default PDN ring and strap widths/pitches are scaled down to avoid failure
# in the PDN generation phase of OpenLane due to tiny die footprint.
set ::env(FP_PDN_VWIDTH) 0.9
set ::env(FP_PDN_HWIDTH) 0.9
set ::env(FP_PDN_VOFFSET) 5
set ::env(FP_PDN_HOFFSET) 5
set ::env(FP_PDN_VPITCH) 40
set ::env(FP_PDN_HPITCH) 40

# No Macro-Hardening Configuration
# v1.0 layout is standard-cell-only. history_sram remains un-hardened and unwired.
set ::env(MACRO_PLACEMENT_CFG) ""
set ::env(PL_MACRO_HALO) ""
set ::env(PL_MACRO_CHANNEL) ""
