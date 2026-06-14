# ==============================================================================
# Genus Synthesis Run Script - 45nm Technology Node
# ==============================================================================

# Source setup variables
source setup.tcl

# Read Verilog sources using filelist
read_hdl -v2001 -f ../../filelists/rtl_filelist.f

# Elaborate top module
elaborate agrisense_ipms_top

# Apply SDC constraints
read_sdc ../constraints/constraints.sdc

# Synthesize design to generic gates
syn_generic

# Map design to target standard cells
syn_map

# Optimize gate-level netlist
syn_opt

# Create reports directory if not exists
file mkdir ../reports

# Generate Synthesis Reports
report_area > ../reports/area.rpt
report_timing > ../reports/timing.rpt
report_power > ../reports/power.rpt
report_gates > ../reports/gates.rpt
report_qor > ../reports/qor.rpt

# Create netlist and outputs directories if not exist
file mkdir ../netlist
file mkdir ../outputs

# Write outputs
write_hdl > ../netlist/agrisense_ipms_top_synth.v
write_sdc > ../outputs/agrisense_ipms_top_synth.sdc
write_db -to_file ../outputs/agrisense_ipms_top_synth.db

puts "=========================================================================="
puts "Genus Synthesis Complete. Netlist and SDC written."
puts "=========================================================================="
exit
