#=======================================================================
# AgriSense-IPMS - Genus Synthesis (90nm)
#
# Run from the PROJECT ROOT (AgriSense-IPMS-Cadence/):
#   genus -files 90nm/genus/run_synth_90nm.tcl -log 90nm/reports/genus.log
#=======================================================================

source ./90nm/genus/setup_90nm.tcl

# ---- 1. Library setup -------------------------------------------------
set_db init_lib_search_path $LIB_DIR
set_db library $LIB_FILE

# ---- 2. RTL read -------------------------------------------------------
set_db init_hdl_search_path "./rtl"
read_hdl -sv -incdir $INCDIR -f $RTL_FILELIST

# ---- 3. Elaborate -------------------------------------------------------
elaborate $TOP_MODULE
check_design -unresolved

# ---- 4. Timing constraints ----------------------------------------------
create_clock -name $CLK_PORT -period $CLK_PERIOD [get_ports $CLK_PORT]
set_ideal_network [get_ports rst_n]
set_clock_uncertainty 0.25 [get_clocks $CLK_PORT]
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
report_area               > $REPORT_DIR/area_90nm.rpt
report_timing              > $REPORT_DIR/timing_90nm.rpt
report_power               > $REPORT_DIR/power_90nm.rpt
report_gates                > $REPORT_DIR/gates_90nm.rpt
report_qor                  > $REPORT_DIR/qor_90nm.rpt

# ---- 7. Outputs for Innovus -----------------------------------------------
file mkdir $NETLIST_DIR
write_hdl                 > $NETLIST_DIR/agrisense_ipms_top_90nm.v
write_sdc                 > $NETLIST_DIR/agrisense_ipms_top_90nm.sdc
write_db -to_file $NETLIST_DIR/agrisense_ipms_top_90nm.db

puts "============================================================"
puts "AgriSense-IPMS 90nm synthesis complete."
puts "Reports : $REPORT_DIR"
puts "Netlist : $NETLIST_DIR/agrisense_ipms_top_90nm.v"
puts "SDC     : $NETLIST_DIR/agrisense_ipms_top_90nm.sdc"
puts "============================================================"

exit
