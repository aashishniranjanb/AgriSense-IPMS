# ==============================================================================
# Innovus Place and Route Setup - 45nm Technology Node
# ==============================================================================

set DESIGN_NAME "agrisense_ipms_top"

# Technology settings (edit to point to your actual 45nm PDK files)
# Example files for NCSU FreePDK45
set library_list [list \
    "../../45nm/lib/gscl45nm.lib" \
]

set lef_list [list \
    "../../45nm/lef/gscl45nm.lef" \
]

# Netlist generated from Genus
set netlist_file "../netlist/agrisense_ipms_top_synth.v"

# SDC constraints file from Genus
set sdc_file "../outputs/agrisense_ipms_top_synth.sdc"

# Optional Captable/QX table for parasitics extraction (uncomment to configure)
# set captable_file "../../45nm/captable/gscl45nm.captable"
