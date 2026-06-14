# ==============================================================================
# Innovus Place and Route Run Script - 90nm Technology Node
# ==============================================================================

# Source setup variables
source setup.tcl

# Initialize design
set init_gnd_net "vssd1"
set init_pwr_net "vccd1"
set init_verilog $netlist_file
set init_lef_file $lef_list
set init_top_cell $DESIGN_NAME
set init_sdc_file $sdc_file

init_design

# 1. Floorplanning
# Core utilization = 35% (0.35)
# Core aspect ratio = 1.0 (square floorplan)
# Core margins = 10 um from chip boundaries
floorPlan -r 1.0 0.35 10 10 10 10

# 2. Power Planning (PDN)
# Connect global power nets (commonly lower-case vdd/gnd for 90nm standard cells)
globalNetConnect vccd1 -type pgpin -pin vdd -inst *
globalNetConnect vssd1 -type pgpin -pin gnd -inst *

# Add power rings around the core boundary
# Width = 1.0 um, Spacing = 0.5 um, Offset = 0.5 um
addRing -nets {vccd1 vssd1} -type core_rings -width 1.0 -spacing 0.5 -offset 0.5 -center 1

# Add power stripes (vertical straps)
# Width = 0.9 um, set-to-set pitch = 40 um
addStripe -nets {vccd1 vssd1} -layer vertical -width 0.9 -spacing 0.5 -set_to_set_distance 40

# 3. Placement
placeDesign
optDesign -preCTS

# 4. Clock Tree Synthesis (CTS)
ccopt_design
optDesign -postCTS

# 5. Routing
routeDesign
optDesign -postRoute

# 6. Design Rule Checking & LVS verification
file mkdir ../reports
verifyGeometry -report ../reports/drc.rpt
verifyConnectivity -report ../reports/lvs.rpt

# 7. Write outputs
file mkdir ../outputs
write_design -basename ../outputs/agrisense_ipms_top_pnr
streamOut ../outputs/agrisense_ipms_top.gds -mapFile gds2lef.map

puts "=========================================================================="
puts "Innovus Place & Route Complete. GDSII and database written."
puts "=========================================================================="
exit
