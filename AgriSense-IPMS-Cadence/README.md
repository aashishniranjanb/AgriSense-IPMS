# AgriSense-IPMS-Cadence
## ASIC Synthesis and Place-and-Route Layout Flows (Cadence Genus / Innovus)
### Technology Nodes: 45nm & 90nm

This repository contains the physical design constraints, synthesis scripts, place-and-route scripts, and synthesizable RTL source copies for the **AgriSense-IPMS** processor targeting Cadence Genus and Innovus tools.

---

## Directory Structure

```text
AgriSense-IPMS-Cadence/
├── README.md                      # This documentation file
├── rtl/                           # 18 synthesizable RTL files (copied from source)
│   ├── common/                    # Always-On and support logic
│   ├── decde/                     # Double-EMA and crossover detection
│   ├── csa/                       # Crop Stress Accelerator
│   ├── dt/                        # Decision Tree Accelerator
│   ├── ipm/                       # Intelligent Power Manager FSM
│   ├── sa_adc/                    # Stress-Aware ADC Controller
│   └── top/                       # Top-level integration wrapper
├── filelists/
│   └── rtl_filelist.f             # Common compile-order file list for Genus
├── 45nm/
│   ├── constraints/
│   │   └── constraints.sdc        # Timing constraints (50 ns / 20 MHz target)
│   ├── genus/
│   │   ├── setup_45nm.tcl         # Genus library & search path setup (45nm)
│   │   └── run_synth_45nm.tcl     # Genus synthesis execution script (45nm)
│   ├── innovus/
│   │   ├── setup_45nm.tcl         # Innovus design configuration setup (45nm)
│   │   └── run_pnr_45nm.tcl       # Innovus place-and-route execution script (45nm)
│   ├── netlist/                   # Directory for synthesized netlists (.gitkeep)
│   ├── outputs/                   # Directory for output GDSII/DB databases (.gitkeep)
│   └── reports/                   # Directory for DRC/LVS/Timing reports (.gitkeep)
├── 90nm/
│   ├── constraints/
│   │   └── constraints.sdc        # Timing constraints (50 ns / 20 MHz target)
│   ├── genus/
│   │   ├── setup_90nm.tcl         # Genus library & search path setup (90nm)
│   │   └── run_synth_90nm.tcl     # Genus synthesis execution script (90nm)
│   ├── innovus/
│   │   ├── setup_90nm.tcl         # Innovus design configuration setup (90nm)
│   │   └── run_pnr_90nm.tcl       # Innovus place-and-route execution script (90nm)
│   ├── netlist/                   # Directory for synthesized netlists (.gitkeep)
│   ├── outputs/                   # Directory for output GDSII/DB databases (.gitkeep)
│   └── reports/                   # Directory for DRC/LVS/Timing reports (.gitkeep)
└── scripts/
    ├── run_all_45nm.sh            # Helper script to run 45nm synthesis + P&R
    └── run_all_90nm.sh            # Helper script to run 90nm synthesis + P&R
```

---

## Configuration Before Running

Because PDK files and directory layouts vary by local installation, you **must customize the PDK library paths** in the setup files before executing the flows:

### 1. Genus Synthesis Setup
Edit the setup file under the target node's `genus/` folder (e.g. `45nm/genus/setup_45nm.tcl` or `90nm/genus/setup_90nm.tcl`):
*   Update `LIB_DIR` and `LIB_FILE` to point to your actual technology library `.lib` database file (e.g. TSMC 90nm cell library or NCSU FreePDK45 library).

### 2. Innovus Place & Route Setup
Edit the setup file under the target node's `innovus/` folder (e.g. `45nm/innovus/setup_45nm.tcl` or `90nm/innovus/setup_90nm.tcl`):
*   Update `LIB_FILE` and `LEF_FILE` to point to the timing `.lib` and physical `.lef` files.
*   Update `GDS_LAYERMAP` to point to your layermap file (e.g., `gds.map`).
*   Verify the power and ground net names in the setup script:
    *   `PWR_NET`: Default is `"VDD"`.
    *   `GND_NET`: Default is `"VSS"`.
    *   Confirm these names against the cell definitions in the `.lib` / `.lef` files.

---

## How to Run

### Batch execution of full flows (Synthesis → Place & Route)
Trigger both synthesis and layout in batch mode using the helper scripts in the `scripts/` directory:
```bash
# To run the complete 45nm flow:
bash scripts/run_all_45nm.sh

# To run the complete 90nm flow:
bash scripts/run_all_90nm.sh
```

### Running individual stages

#### Genus Synthesis:
```bash
# For 45nm node:
genus -files 45nm/genus/run_synth_45nm.tcl -log 45nm/reports/genus.log

# For 90nm node:
genus -files 90nm/genus/run_synth_90nm.tcl -log 90nm/reports/genus.log
```
Outputs (synthesized netlist and constraints) will be written to the target node's `netlist/` and `outputs/`. Synthesis reports will be written to the target node's `reports/`.

#### Innovus Place & Route:
*(Requires the corresponding Genus synthesis outputs to exist)*
```bash
# For 45nm node:
innovus -files 45nm/innovus/run_pnr_45nm.tcl -log 45nm/reports/innovus.log

# For 90nm node:
innovus -files 90nm/innovus/run_pnr_90nm.tcl -log 90nm/reports/innovus.log
```
Outputs (final GDSII database, P&R netlist, and saved design database) will be written to the target node's `outputs/`. Design DRC, LVS, and post-layout timing/power reports will be written to `reports/`.
