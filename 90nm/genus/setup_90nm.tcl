#=======================================================================
# AgriSense-IPMS - Genus Setup (90nm)
# Edit ONLY this file when the lab's library/LEF paths change.
#
# NOTE: The 90nm PDK path/filenames below MIRROR the 45nm convention
# given by the lab (/home/Cadence/FOUNDRY/digital/<node>/...). Before
# first run, verify on the lab machine with:
#
#   ls /home/Cadence/FOUNDRY/digital/90nm/LIBS/lib/typ/
#   ls /home/Cadence/FOUNDRY/digital/90nm/LEF/
#
# 90nm academic PDKs sometimes use different corner names
# (e.g. "tt.lib", "slow.lib"/"fast.lib", "ss_125C.lib"). Update
# LIB_FILE below to match whatever actually exists.
#=======================================================================

# ---- Design ----------------------------------------------------------
set TOP_MODULE      "agrisense_ipms_top"
set RTL_FILELIST    "./filelists/rtl_filelist.f"
set INCDIR          "./rtl/common"

# ---- Timing target ------------------------------------------------
# 90nm is slower than 45nm; start more relaxed than the 45nm 10ns run.
# crop_stress_accelerator (5x 8-bit multipliers + adder tree) is the
# expected critical path. Start at 15-20ns and report achieved Fmax.
set CLK_PERIOD      20
set CLK_PORT        "clk"

# ---- 90nm Library / LEF (college lab paths - VERIFY before running) ----
set LIB_DIR  "/home/Cadence/FOUNDRY/digital/90nm/LIBS/lib/typ"
set LIB_FILE "$LIB_DIR/typical.lib"
# Optional fast corner:
# set LIB_FILE_FAST "/home/Cadence/FOUNDRY/digital/90nm/LIBS/lib/fast/fast.lib"

set LEF_DIR  "/home/Cadence/FOUNDRY/digital/90nm/LEF"
set LEF_FILE "$LEF_DIR/header.lef"

# ---- Output locations --------------------------------------------------
set REPORT_DIR  "./90nm/reports"
set NETLIST_DIR "./90nm/netlist"
