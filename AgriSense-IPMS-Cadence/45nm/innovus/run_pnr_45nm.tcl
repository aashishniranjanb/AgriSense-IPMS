#=======================================================================
# AgriSense-IPMS - Innovus P&R (45nm)
#
# Run from the PROJECT ROOT (AgriSense-IPMS-Cadence/), after
# 45nm/genus/run_synth_45nm.tcl has produced the netlist + SDC:
#
#   innovus -files 45nm/innovus/run_pnr_45nm.tcl -log 45nm/reports/innovus.log
#=======================================================================

source ./45nm/innovus/setup_45nm.tcl
file mkdir $REPORT_DIR
file mkdir $OUT_DIR/gds
file mkdir $OUT_DIR/db

# ---- 1. Import design --------------------------------------------------
init_design -init_verilog $NETLIST_FILE \
            -init_top_cell $TOP_MODULE \
            -init_lef_file $LEF_FILE \
            -init_mmmc_file "" \
            -init_abs_path 1

# If init_mmmc_file is required by your Innovus version instead of a
# bare .lib, generate a minimal MMMC view file from $LIB_FILE first
# (ask lab admin for the standard MMMC template used by other groups).

# ---- 2. Timing constraints -----------------------------------------------
loadTimingConstraint $SDC_FILE

# ---- 3. Floorplan ----------------------------------------------------------
floorplan -r $FP_ASPECT $FP_UTIL $FP_MARGIN $FP_MARGIN $FP_MARGIN $FP_MARGIN

# ---- 4. Power/Ground connections -------------------------------------------
globalNetConnect $PWR_NET -type pgpin -pin $PWR_NET -inst *
globalNetConnect $GND_NET -type pgpin -pin $GND_NET -inst *

# Power rings/stripes - uncomment and tune if PDN step is required
# by your Innovus version:
# addRing -nets "$PWR_NET $GND_NET" -width 1.0 -spacing 1.0 -layer {top metal6 bottom metal6 left metal5 right metal5}
# addStripe -nets "$PWR_NET $GND_NET" -layer metal5 -width 1.0 -spacing 4.0 -set_to_set_distance 20

# ---- 5. Placement -----------------------------------------------------------
place_design

# ---- 6. Clock Tree Synthesis -------------------------------------------------
ccopt_design

# ---- 7. Routing ---------------------------------------------------------------
routeDesign

# ---- 8. Sign-off checks -----------------------------------------------------------
verify_drc           > $REPORT_DIR/drc_45nm.rpt
verifyConnectivity    > $REPORT_DIR/lvs_conn_45nm.rpt

# ---- 9. Final timing & power (post-route) ---------------------------------------
timeDesign -postRoute > $REPORT_DIR/timing_postroute_45nm.rpt
report_power          > $REPORT_DIR/power_postroute_45nm.rpt
report_area           > $REPORT_DIR/area_postroute_45nm.rpt

# ---- 10. Save design + GDS streamout ---------------------------------------------
saveDesign $OUT_DIR/db/agrisense_ipms_top_45nm.enc

# streamOut needs a layer map; if GDS_LAYERMAP doesn't exist on the lab
# machine, comment this out and ask the lab admin for the correct path.
if {[file exists $GDS_LAYERMAP]} {
    streamOut $OUT_DIR/gds/agrisense_ipms_top_45nm.gds \
        -mapFile $GDS_LAYERMAP \
        -libName AgriSenseLib \
        -units 1000 \
        -mode ALL
} else {
    puts "WARNING: GDS layer map not found at $GDS_LAYERMAP"
    puts "         Skipping streamOut. Ask lab admin for the correct"
    puts "         layermap path and re-run streamOut manually."
}

puts "============================================================"
puts "AgriSense-IPMS 45nm P&R complete."
puts "Reports : $REPORT_DIR"
puts "DB      : $OUT_DIR/db/agrisense_ipms_top_45nm.enc"
puts "GDS     : $OUT_DIR/gds/agrisense_ipms_top_45nm.gds (if layermap found)"
puts "============================================================"
