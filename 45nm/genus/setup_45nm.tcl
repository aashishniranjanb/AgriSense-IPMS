#=======================================================================
# AgriSense-IPMS - Genus Setup (45nm)
# Edit ONLY this file when the lab's library/LEF paths change.
# All other scripts source this file.
#=======================================================================

# ---- Design ----------------------------------------------------------
set TOP_MODULE      "agrisense_ipms_top"
set RTL_FILELIST    "./filelists/rtl_filelist.f"
set INCDIR          "./rtl/common"

# ---- Timing target ------------------------------------------------
# Reference example used 10ns (100MHz). crop_stress_accelerator
# (5x 8-bit multipliers + adder tree, ~2.4k cells) is the expected
# critical path. Start at 10ns; if syn_opt cannot close timing,
# re-run with CLK_PERIOD 15 or 20 and report the achieved Fmax
# honestly in the paper rather than forcing 100MHz.
set CLK_PERIOD      10
set CLK_PORT        "clk"

# ---- 45nm Library / LEF (college lab paths) --------------------------
# >>> Update these two lines only if the lab path layout changes <<<
set LIB_DIR  "/home/Cadence/FOUNDRY/digital/45nm/LIBS/lib/typ"
set LIB_FILE "$LIB_DIR/typical.lib"
# Optional fast corner (uncomment to add for multi-corner reporting):
# set LIB_FILE_FAST "/home/Cadence/FOUNDRY/digital/45nm/LIBS/lib/fast/fast.lib"

set LEF_DIR  "/home/Cadence/FOUNDRY/digital/45nm/LEF"
set LEF_FILE "$LEF_DIR/header.lef"

# ---- Output locations --------------------------------------------------
set REPORT_DIR  "./45nm/reports"
set NETLIST_DIR "./45nm/netlist"
