# ==============================================================================
# Genus Synthesis Setup - 45nm Technology Node
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

# Target library definition (edit to point to your actual 45nm .lib file)
# Example: gscl45nm.lib is a common library name for the NCSU FreePDK45.
set library_list [list \
    "gscl45nm.lib" \
]

set_db library $library_list

# LEF files for physical layout and area estimation (optional during synthesis)
# set lef_list [list "gscl45nm.lef"]
# set_db lef_files $lef_list
