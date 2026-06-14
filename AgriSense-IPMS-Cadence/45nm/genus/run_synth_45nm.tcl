#=======================================================================
# AgriSense-IPMS - Genus Synthesis (45nm)
#
# Run from the PROJECT ROOT (AgriSense-IPMS-Cadence/):
#   genus -files 45nm/genus/run_synth_45nm.tcl -log 45nm/reports/genus.log
#=======================================================================

source ./45nm/genus/setup_45nm.tcl

# ---- 1. Library setup -------------------------------------------------
set_db init_lib_search_path $LIB_DIR
set_db library $LIB_FILE
# If using a fast corner too:
# set_db library "$LIB_FILE $LIB_FILE_FAST"

# ---- 2. RTL read -------------------------------------------------------
set_db init_hdl_search_path "./rtl"
read_hdl -sv -incdir $INCDIR -f $RTL_FILELIST

# ---- 3. Elaborate -------------------------------------------------------
elaborate $TOP_MODULE
check_design -unresolved

# ---- 4. Timing constraints ----------------------------------------------
create_clock -name $CLK_PORT -period $CLK_PERIOD [get_ports $CLK_PORT]
# rst_n is async, treat as ideal / exclude from timing
set_ideal_network [get_ports rst_n]
set_clock_uncertainty 0.2 [get_clocks $CLK_PORT]
set_input_delay  [expr $CLK_PERIOD * 0.3] -clock $CLK_PORT \
    [remove_from_collection [all_inputs] [get_ports "$CLK_PORT rst_n"]]
set_output_delay [expr $CLK_PERIOD * 0.3] -clock $CLK_PORT [all_outputs]

# ---- 5. Synthesis (generic -> map -> opt) -------------------------------
set_db syn_global_effort medium

syn_gen
syn_map
syn_opt

# ---- 6. Reports ----------------------------------------------------------
file mkdir $REPORT_DIR
report_area               > $REPORT_DIR/area_45nm.rpt
report_timing              > $REPORT_DIR/timing_45nm.rpt
report_power               > $REPORT_DIR/power_45nm.rpt
report_gates                > $REPORT_DIR/gates_45nm.rpt
report_qor                  > $REPORT_DIR/qor_45nm.rpt

# ---- 7. Outputs for Innovus -----------------------------------------------
file mkdir $NETLIST_DIR
write_hdl                 > $NETLIST_DIR/agrisense_ipms_top_45nm.v
write_sdc                 > $NETLIST_DIR/agrisense_ipms_top_45nm.sdc
write_db -to_file $NETLIST_DIR/agrisense_ipms_top_45nm.db

puts "============================================================"
puts "AgriSense-IPMS 45nm synthesis complete."
puts "Reports : $REPORT_DIR"
puts "Netlist : $NETLIST_DIR/agrisense_ipms_top_45nm.v"
puts "SDC     : $NETLIST_DIR/agrisense_ipms_top_45nm.sdc"
puts "============================================================"

exit
