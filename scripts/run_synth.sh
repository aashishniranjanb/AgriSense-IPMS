#!/usr/bin/env bash
# run_synth.sh — Full OpenROAD block + top synthesis
# Run inside GitHub Codespaces (oss-cad-suite container)
# Produces Table II data for the paper

set -e
PROJ_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPORT_DIR="$PROJ_ROOT/synth/reports"
mkdir -p "$REPORT_DIR"

RTL_FILES=(
  "$PROJ_ROOT/rtl/common/isolation_cell.v"
  "$PROJ_ROOT/rtl/common/reg_bus_interconnect.v"
  "$PROJ_ROOT/rtl/common/register_file.v"
  "$PROJ_ROOT/rtl/common/synchronizer.v"
  "$PROJ_ROOT/rtl/decde/ema_filter.v"
  "$PROJ_ROOT/rtl/decde/crossover_detector.v"
  "$PROJ_ROOT/rtl/decde/decde_channel.v"
  "$PROJ_ROOT/rtl/decde/fusion_unit.v"
  "$PROJ_ROOT/rtl/csa/weighted_sum.v"
  "$PROJ_ROOT/rtl/csa/normalization_unit.v"
  "$PROJ_ROOT/rtl/csa/crop_stress_accelerator.v"
  "$PROJ_ROOT/rtl/dt/decision_tree_accelerator.v"
  "$PROJ_ROOT/rtl/ipm/ipm_fsm.v"
  "$PROJ_ROOT/rtl/ipm/power_controller.v"
  "$PROJ_ROOT/rtl/ipm/wake_controller.v"
  "$PROJ_ROOT/rtl/sa_adc/sa_adc_controller.v"
  "$PROJ_ROOT/rtl/top/agrisense_ipms_top.v"
)

INCLUDE="+incdir+$PROJ_ROOT/rtl/common"

# ============================================================
# Helper: synthesize a single top module with Yosys
# ============================================================
synth_block() {
  local TOP="$1"
  local REPORT="$REPORT_DIR/${TOP}_synth.rpt"
  echo ""
  echo "--- Synthesizing: $TOP ---"
  yosys -p "
    read_verilog $INCLUDE ${RTL_FILES[*]}
    hierarchy -check -top $TOP
    proc; opt; techmap; opt
    stat -top $TOP
  " 2>&1 | tee "$REPORT"
  echo "    Report: $REPORT"
}

# ============================================================
# Step 1: Verilator Lint (zero warnings required)
# ============================================================
echo "========================================"
echo " STEP 1: Verilator --lint-only -Wall"
echo "========================================"
verilator --lint-only -Wall --top-module agrisense_ipms_top \
  $INCLUDE "${RTL_FILES[@]}" \
  && echo "VERILATOR: PASS" \
  || { echo "VERILATOR: FAIL — fix warnings before synthesis"; exit 1; }

# ============================================================
# Step 2: Yosys hierarchy check + stat (no PDK, just gates)
# ============================================================
echo ""
echo "========================================"
echo " STEP 2: Yosys Block Synthesis"
echo "========================================"

synth_block "sa_adc_controller"
synth_block "fusion_unit"
synth_block "crop_stress_accelerator"
synth_block "decision_tree_accelerator"
synth_block "ipm_fsm"
synth_block "register_file"

# ============================================================
# Step 3: Top-level synthesis
# ============================================================
echo ""
echo "========================================"
echo " STEP 3: Top-Level Synthesis"
echo "========================================"
synth_block "agrisense_ipms_top"

# ============================================================
# Step 4: Summary Table (Table II data)
# ============================================================
echo ""
echo "========================================"
echo " SYNTHESIS SUMMARY — Table II Data"
echo "========================================"
echo " Block                     | Cells | Wires"
echo "---------------------------|-------|------"
for TOP in sa_adc_controller fusion_unit crop_stress_accelerator \
           decision_tree_accelerator ipm_fsm register_file agrisense_ipms_top; do
  REPORT="$REPORT_DIR/${TOP}_synth.rpt"
  if [[ -f "$REPORT" ]]; then
    CELLS=$(grep "Number of cells:" "$REPORT" | tail -1 | awk '{print $NF}')
    WIRES=$(grep "Number of wires:" "$REPORT" | tail -1 | awk '{print $NF}')
    printf " %-26s | %-5s | %s\n" "$TOP" "${CELLS:-N/A}" "${WIRES:-N/A}"
  fi
done

echo ""
echo "All reports saved to: $REPORT_DIR/"
echo "Run activity analysis: python scripts/activity_analysis.py"
