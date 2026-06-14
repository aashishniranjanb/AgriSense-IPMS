#=======================================================================
# AgriSense-IPMS - Innovus Setup (90nm)
# VERIFY paths/filenames on the lab machine before first run (see
# notes in 90nm/genus/setup_90nm.tcl).
#=======================================================================

set TOP_MODULE   "agrisense_ipms_top"

# ---- Inputs from Genus --------------------------------------------------
set NETLIST_FILE "./90nm/netlist/agrisense_ipms_top_90nm.v"
set SDC_FILE     "./90nm/netlist/agrisense_ipms_top_90nm.sdc"

# ---- 90nm Physical / Timing libraries (college lab paths - VERIFY) -----
set LEF_FILE  "/home/Cadence/FOUNDRY/digital/90nm/LEF/header.lef"
set LIB_FILE  "/home/Cadence/FOUNDRY/digital/90nm/LIBS/lib/typ/typical.lib"

set GDS_LAYERMAP "/home/Cadence/FOUNDRY/digital/90nm/LEF/gds.map"

# ---- Power nets -----------------------------------------------------------
# Check the 90nm .lib pg_pin names with: grep -i "pg_pin" $LIB_FILE | head
set PWR_NET "VDD"
set GND_NET "VSS"

# ---- Floorplan (small design ~14k cells; 90nm cells are larger than
# 45nm, so the same utilization gives a larger die - that's fine) ------
set FP_ASPECT  1.0
set FP_UTIL    0.55
set FP_MARGIN  8.0

# ---- Output locations ----------------------------------------------------
set REPORT_DIR  "./90nm/reports"
set OUT_DIR     "./90nm/outputs"
