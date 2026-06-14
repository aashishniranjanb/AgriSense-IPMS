#!/usr/bin/env bash
# setup.sh - AgriSense-IPMS Codespaces post-create setup
# Runs inside ghcr.io/yosyshq/oss-cad-suite container

set -e
echo "=========================================="
echo " AgriSense-IPMS Codespace Setup"
echo " Tools: Yosys, Verilator, OpenROAD"
echo "=========================================="

# Install Yosys, Verilator, and IVerilog
echo ""
echo "[0/4] Installing Yosys, Verilator, and IVerilog via apt-get..."
sudo apt-get update
sudo apt-get install -y yosys verilator iverilog

# Verify tool availability
echo ""
echo "[1/4] Verifying synthesis tools..."
yosys -V
verilator --version | head -1
openroad -version 2>/dev/null || echo "  OpenROAD: not in this image variant (will require OpenROAD-flow-scripts build)"

# Install Python dependencies
echo ""
echo "[2/4] Installing Python dependencies..."
pip install --quiet numpy pandas matplotlib

# Generate synthetic traces
echo ""
echo "[3/4] Generating sensor traces..."
python sim/scripts/generate_traces.py

# Run Verilator lint
echo ""
echo "[4/4] Running Verilator lint check..."
verilator --lint-only -Wall --top-module agrisense_ipms_top \
  +incdir+rtl/common \
  rtl/common/isolation_cell.v \
  rtl/common/reg_bus_interconnect.v \
  rtl/common/register_file.v \
  rtl/common/synchronizer.v \
  rtl/decde/ema_filter.v \
  rtl/decde/crossover_detector.v \
  rtl/decde/decde_channel.v \
  rtl/decde/fusion_unit.v \
  rtl/csa/weighted_sum.v \
  rtl/csa/normalization_unit.v \
  rtl/csa/crop_stress_accelerator.v \
  rtl/dt/decision_tree_accelerator.v \
  rtl/ipm/ipm_fsm.v \
  rtl/ipm/power_controller.v \
  rtl/ipm/wake_controller.v \
  rtl/sa_adc/sa_adc_controller.v \
  rtl/top/agrisense_ipms_top.v \
  && echo "  Verilator: PASS (0 warnings)" \
  || echo "  Verilator: WARNINGS FOUND - check output above"

echo ""
echo "=========================================="
echo " Setup complete. Ready for synthesis."
echo " Run: bash scripts/run_synth.sh"
echo "=========================================="
