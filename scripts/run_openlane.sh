#!/usr/bin/env bash
# run_openlane.sh - AgriSense-IPMS OpenLane layout flow automation
# Designed to run inside the Ubuntu-based GitHub Codespaces environment.

set -e

# Setup paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJ_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=========================================================="
echo " AgriSense-IPMS OpenLane GDSII Physical Design Flow"
echo "=========================================================="

# 1. Check if OPENLANE_ROOT and PDK_ROOT are set
if [ -z "$OPENLANE_ROOT" ]; then
    # Fallback to check default paths
    if [ -d "/workspaces/OpenROAD-flow-scripts/openlane" ]; then
        export OPENLANE_ROOT="/workspaces/OpenROAD-flow-scripts/openlane"
    elif [ -d "$HOME/OpenROAD-flow-scripts/openlane" ]; then
        export OPENLANE_ROOT="$HOME/OpenROAD-flow-scripts/openlane"
    else
        echo "Error: OPENLANE_ROOT is not set and OpenLane was not found in default paths."
        echo "Please install OpenLane or set \$OPENLANE_ROOT env variable."
        exit 1
    fi
fi

if [ -z "$PDK_ROOT" ]; then
    export PDK_ROOT="/usr/local/share/pdk"
    if [ ! -d "$PDK_ROOT" ]; then
        export PDK_ROOT="$HOME/pdk"
    fi
fi

echo "  OPENLANE_ROOT: $OPENLANE_ROOT"
echo "  PDK_ROOT:      $PDK_ROOT"
echo "  Project Root:  $PROJ_ROOT"

# 2. Stage OpenLane Design Directory
echo ""
echo "[1/4] Staging design files inside OpenLane..."
DESIGN_DIR="$OPENLANE_ROOT/designs/agrisense_ipms_top"
mkdir -p "$DESIGN_DIR"
cp "$PROJ_ROOT/synth/openlane/top/config.tcl" "$DESIGN_DIR/config.tcl"
cp "$PROJ_ROOT/synth/openlane/top/config.json" "$DESIGN_DIR/config.json"

# 3. Run OpenLane Flow (Synthesis to Signoff)
echo ""
echo "[2/4] Executing OpenLane RTL-to-GDSII flow..."
cd "$OPENLANE_ROOT"
./flow.tcl -design agrisense_ipms_top -tag openlane_run -overwrite

RUN_DIR="$DESIGN_DIR/runs/openlane_run"
echo ""
echo "  OpenLane run finished."
echo "  GDSII database:     $RUN_DIR/results/signoff/agrisense_ipms_top.gds"
echo "  Gate-level netlist: $RUN_DIR/results/signoff/agrisense_ipms_top.v"

# 4. Gate-Level Simulation
echo ""
echo "[3/4] Running Gate-Level Simulation with switching activity dump..."
PDK_VERILOG="$PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/verilog/sky130_fd_sc_hd.v"
if [ ! -f "$PDK_VERILOG" ]; then
    # Try alternate location inside pdk
    PDK_VERILOG=$(find "$PDK_ROOT" -name "sky130_fd_sc_hd.v" | head -n 1)
fi

if [ -z "$PDK_VERILOG" ] || [ ! -f "$PDK_VERILOG" ]; then
    echo "Warning: sky130_fd_sc_hd.v standard cell models not found."
    echo "Skipping gate-level VCD generation."
else
    echo "  Found standard cell library models at: $PDK_VERILOG"
    cd "$PROJ_ROOT"
    mkdir -p sim
    
    # Compile gate-level netlist with tb_top and DUMP_ALL macro
    iverilog -DFUNCTIONAL -DGL -DDUMP_ALL -o sim/gate_tb \
        -I rtl/common \
        "$PDK_VERILOG" \
        "$RUN_DIR/results/signoff/agrisense_ipms_top.v" \
        tb/tb_top.v
        
    # Execute simulation to generate tb_top.vcd containing all toggling data
    ./sim/gate_tb
    
    # Rename VCD to distinct name
    mv tb_top.vcd sim/gate_activity.vcd
    echo "  VCD activity trace generated at: sim/gate_activity.vcd"
fi

# 5. OpenROAD Dynamic Power Analysis
echo ""
echo "[4/4] Generating activity-driven power report using OpenROAD..."
PDK_LIBERTY="$PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"
if [ ! -f "$PDK_LIBERTY" ]; then
    PDK_LIBERTY=$(find "$PDK_ROOT" -name "sky130_fd_sc_hd__tt_025C_1v80.lib" | head -n 1)
fi

if [ -z "$PDK_LIBERTY" ] || [ ! -f "$PDK_LIBERTY" ]; then
    echo "Error: sky130_fd_sc_hd__tt_025C_1v80.lib not found. Cannot run OpenROAD power analysis."
    exit 1
fi

SPEF_FILE="$RUN_DIR/results/routing/agrisense_ipms_top.spef"
if [ ! -f "$SPEF_FILE" ]; then
    # Check alternate signoff directory
    SPEF_FILE="$RUN_DIR/results/signoff/agrisense_ipms_top.spef"
fi

if [ -f "$PROJ_ROOT/sim/gate_activity.vcd" ] && [ -f "$SPEF_FILE" ]; then
    cd "$PROJ_ROOT"
    
    # Execute OpenROAD to compute dynamic power based on layout RC parasitics + simulation VCD
    openroad -no_init -exit <<EOF
read_liberty $PDK_LIBERTY
read_verilog $RUN_DIR/results/signoff/agrisense_ipms_top.v
link_design agrisense_ipms_top
read_spef $SPEF_FILE
read_activity -vcd sim/gate_activity.vcd
report_power
EOF
else
    echo "Skipping OpenROAD power analysis (either VCD or SPEF file is missing)."
fi

echo "=========================================================="
echo " Flow execution complete!"
echo "=========================================================="
