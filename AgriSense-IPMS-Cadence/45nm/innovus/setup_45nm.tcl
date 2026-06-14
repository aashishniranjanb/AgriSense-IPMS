#=======================================================================
# AgriSense-IPMS - Innovus Setup (45nm)
# Edit ONLY this file when the lab's LEF/LIB/layermap paths change.
#=======================================================================

set TOP_MODULE   "agrisense_ipms_top"

# ---- Inputs from Genus --------------------------------------------------
set NETLIST_FILE "./45nm/netlist/agrisense_ipms_top_45nm.v"
set SDC_FILE     "./45nm/netlist/agrisense_ipms_top_45nm.sdc"

# ---- 45nm Physical / Timing libraries (college lab paths) -------------
# >>> Update these if the lab path layout changes <<<
set LEF_FILE  "/home/Cadence/FOUNDRY/digital/45nm/LEF/header.lef"
set LIB_FILE  "/home/Cadence/FOUNDRY/digital/45nm/LIBS/lib/typ/typical.lib"

# GDS layer map (ask lab admin if filename differs; common names:
# "gds.map", "cds.lyp2map", "<pdk>.layermap")
set GDS_LAYERMAP "/home/Cadence/FOUNDRY/digital/45nm/LEF/gds.map"

# ---- Power nets -----------------------------------------------------------
# Check the 45nm .lib pg_pin names with: grep -i "pg_pin" $LIB_FILE | head
set PWR_NET "VDD"
set GND_NET "VSS"

# ---- Floorplan (small design ~14k cells -> small/conservative die) -----
# floorplan -r <aspect> <core_util> <left> <bottom> <right> <top>  (microns)
set FP_ASPECT  1.0
set FP_UTIL    0.55
set FP_MARGIN  5.0

# ---- Output locations ----------------------------------------------------
set REPORT_DIR  "./45nm/reports"
set OUT_DIR     "./45nm/outputs"
