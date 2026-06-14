#!/usr/bin/env bash
# run_all_45nm.sh - Helper script to run Genus and Innovus flows for 45nm
# Launches both tools in batch mode.

set -e

# Setup paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NODE_DIR="$(cd "$SCRIPT_DIR/../45nm" && pwd)"

echo "=========================================================="
echo " Running Cadence 45nm Synthesis Flow (Genus)"
echo "=========================================================="
cd "$NODE_DIR/genus"
genus -files run_synth_45nm.tcl -log genus.log -overwrite

echo ""
echo "=========================================================="
echo " Running Cadence 45nm Place & Route Flow (Innovus)"
echo "=========================================================="
cd "$NODE_DIR/innovus"
innovus -files run_pnr_45nm.tcl -log innovus.log -overwrite

echo "=========================================================="
echo " 45nm Cadence Flow Run Complete!"
echo "=========================================================="
