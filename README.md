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
│   │   ├── setup.tcl              # Genus library & search path setup (45nm)
│   │   └── run_synth.tcl          # Genus synthesis execution script
│   ├── innovus/
│   │   ├── setup.tcl              # Innovus design configuration setup (45nm)
│   │   └── run_pnr.tcl            # Innovus place-and-route execution script
│   ├── netlist/                   # Directory for synthesized netlists (.gitkeep)
│   ├── outputs/                   # Directory for output GDSII/DB databases (.gitkeep)
│   └── reports/                   # Directory for DRC/LVS/Timing reports (.gitkeep)
├── 90nm/
│   ├── constraints/
│   │   └── constraints.sdc        # Timing constraints (50 ns / 20 MHz target)
│   ├── genus/
│   │   ├── setup.tcl              # Genus library & search path setup (90nm)
│   │   └── run_synth.tcl          # Genus synthesis execution script
│   ├── innovus/
│   │   ├── setup.tcl              # Innovus design configuration setup (90nm)
│   │   └── run_pnr.tcl            # Innovus place-and-route execution script
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
Edit `setup.tcl` under the target node's `genus/` folder (e.g. `45nm/genus/setup.tcl` or `90nm/genus/setup.tcl`):
*   Update `library_list` to point to your actual technology library `.lib` database file (e.g. TSMC 90nm cell library or NCSU FreePDK45 library).

### 2. Innovus Place & Route Setup
Edit `setup.tcl` under the target node's `innovus/` folder (e.g. `45nm/innovus/setup.tcl` or `90nm/innovus/setup.tcl`):
*   Update `library_list` to point to the P&R `.lib` database file.
*   Update `lef_list` to point to the technology `.lef` and cell `.lef` files.
*   Verify the power and ground pin names of the standard cell library in `run_pnr.tcl`:
    *   By default, `run_pnr.tcl` performs global PG connections to `VDD` / `GND` for 45nm and `vdd` / `gnd` for 90nm standard cell base pins. Verify and adjust these pin names (e.g., to `VPWR` / `VGND` or `VDD` / `VSS`) to match your target library definitions.

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
cd 45nm/genus
genus -files run_synth.tcl
```
Outputs (synthesized netlist and constraints) will be written to `45nm/netlist/` and `45nm/outputs/`. Synthesis area, timing, power, gate, and QoR reports will be written to `45nm/reports/`.

#### Innovus Place & Route:
*(Requires the Genus synthesis outputs in `45nm/netlist/` and `45nm/outputs/` to exist)*
```bash
cd 45nm/innovus
innovus -files run_pnr.tcl
```
Outputs (final GDSII database, P&R netlist, and saved design database) will be written to `45nm/outputs/`. Design DRC, LVS, and post-layout timing/power reports will be written to `45nm/reports/`.
