# ==============================================================================
# Innovus Place and Route Setup - 90nm Technology Node
# ==============================================================================

set DESIGN_NAME "agrisense_ipms_top"

# Technology settings (edit to point to your actual 90nm PDK files)
# Example files for standard 90nm PDK cell libraries
set library_list [list \
    "../../90nm/lib/tcbn90g.lib" \
]

set lef_list [list \
    "../../90nm/lef/tcbn90g.lef" \
]

# Netlist generated from Genus
set netlist_file "../netlist/agrisense_ipms_top_synth.v"

# SDC constraints file from Genus
set sdc_file "../outputs/agrisense_ipms_top_synth.sdc"

# Optional Captable/QX table for parasitics extraction (uncomment to configure)
# set captable_file "../../90nm/captable/tcbn90g.captable"
