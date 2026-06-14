#!/usr/bin/env bash
# run_all_90nm.sh - Helper script to run Genus and Innovus flows for 90nm
# Launches both tools in batch mode.

set -e

# Setup paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NODE_DIR="$(cd "$SCRIPT_DIR/../90nm" && pwd)"

echo "=========================================================="
echo " Running Cadence 90nm Synthesis Flow (Genus)"
echo "=========================================================="
cd "$NODE_DIR/genus"
genus -files run_synth.tcl -log genus.log -overwrite

echo ""
echo "=========================================================="
echo " Running Cadence 90nm Place & Route Flow (Innovus)"
echo "=========================================================="
cd "$NODE_DIR/innovus"
innovus -files run_pnr.tcl -log innovus.log -overwrite

echo "=========================================================="
echo " 90nm Cadence Flow Run Complete!"
echo "=========================================================="
