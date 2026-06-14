# ==============================================================================
# Genus Synthesis Setup - 90nm Technology Node
# ==============================================================================

# Search paths for libraries and design files
set_db init_search_path [list \
    "." \
    "../../filelists" \
    "../../rtl/common" \
    "../../rtl/decde" \
    "../../rtl/csa" \
    "../../rtl/dt" \
    "../../rtl/ipm" \
    "../../rtl/sa_adc" \
    "../../rtl/top" \
]

# Target library definition (edit to point to your actual 90nm .lib file)
# Example: tcbn90g.lib is a standard TSMC 90nm library name.
set library_list [list \
    "tcbn90g.lib" \
]

set_db library $library_list

# LEF files for physical layout and area estimation (optional during synthesis)
# set lef_list [list "tcbn90g.lef"]
# set_db lef_files $lef_list
