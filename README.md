# AgriSense-IPMS
## Intelligent Power Management SoC for Precision Agriculture
### RTL v1.0 — `rtl_v1_0_freeze` — IEEE WinTechCon 2026 Submission

[![Vivado Compile](https://img.shields.io/badge/Vivado_Lint-PASS-brightgreen)]()
[![RTL Freeze](https://img.shields.io/badge/RTL-v1.0_frozen-blue)]()
[![Synthesis](https://img.shields.io/badge/OpenROAD-ready-orange)]()

---

## Overview

AgriSense-IPMS is a synthesizable ASIC architecture for **crop-stress monitoring** in precision agriculture. It implements a full hierarchical wake pipeline that wakes up progressively higher-power compute domains only when multi-sensor correlation detects genuine agricultural stress events.

The chip achieves energy efficiency by keeping high-power Domain 2 compute blocks (CSA, Decision Tree) and Domain 3 communication blocks (LoRa) powered off >85% of the time during nominal field conditions.

---

## Architecture — Three Core Contributions

```
Sensors (×5)
     │
     ▼
┌─────────────────────────────────────────────────┐
│ DOMAIN 1 — Always-On (μW range)                 │
│                                                  │
│  ┌──────────────┐   ┌───────────────────────┐   │
│  │ Register File │   │  IPM FSM              │   │
│  │ (256×8b, FF) │   │  SLEEP/MONITOR/       │   │
│  │  + ΣW Checker │   │  WARNING/CRITICAL     │   │
│  └──────────────┘   │  + 2-cycle hysteresis  │   │
│                      └───────────────────────┘   │
│  ┌───────────────────────────────────────────┐   │
│  │ DECDE (×5 channels)                       │   │
│  │  EMA Fast + EMA Slow → Crossover Detector │   │
│  │  → Fusion Unit (Direction-Aware, Window)  │   │
│  └───────────────────────────────────────────┘   │
└─────────────────────────────────────────────────┘
     │ stress_event
     ▼
┌─────────────────────────────────────────────────┐
│ DOMAIN 2 — Gated (mW range, event-driven)       │
│                                                  │
│  ┌──────────────────────────────────────────┐   │
│  │ Contribution 1: SA-ADC Controller        │   │
│  │   stress_score → adaptive resolution     │   │
│  │   (8-bit/10-bit/12-bit per channel)      │   │
│  └──────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────┐   │
│  │ Contribution 2: Crop Stress Accelerator  │   │
│  │   Weighted sum (ΣW=64 invariant)         │   │
│  │   → stress_score [7:0]                   │   │
│  └──────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────┐   │
│  │ Contribution 3: Decision Tree (7 nodes)  │   │
│  │   Programmable thresholds T0–T6          │   │
│  │   → leaf_output {severity[1:0], type[1:0]}│  │
│  └──────────────────────────────────────────┘   │
└─────────────────────────────────────────────────┘
     │ severity == CRITICAL
     ▼
┌─────────────────────────────────────────────────┐
│ DOMAIN 3 — Gated (mW range, alert-only)         │
│  comm_en → LoRa alert (stub, future work)        │
└─────────────────────────────────────────────────┘
```

---

## Repository Structure

```
AgriSense-IPMS/
├── rtl/
│   ├── common/          # Register file, bus, isolation, sync
│   ├── decde/           # EMA filter, crossover detector, fusion unit
│   ├── csa/             # Weighted sum, normalization, CSA
│   ├── dt/              # Decision tree accelerator
│   ├── ipm/             # IPM FSM, power controller, wake controller
│   ├── sa_adc/          # Stress-aware ADC controller
│   └── top/             # agrisense_ipms_top.v
├── tb/                  # Unit + system testbenches (Vivado xsim)
├── docs/                # Architecture docs, register map, FSM spec
├── sim/
│   ├── scripts/         # generate_traces.py (6 agricultural scenarios)
│   └── traces/          # Synthetic sensor CSVs (200 samples each)
├── synth/
│   ├── openroad_freeze/ # Frozen RTL copy for synthesis
│   ├── openlane/        # Yosys/OpenROAD Tcl scripts per block
│   └── reports/         # Synthesis results (post-OpenROAD)
├── scripts/             # lint.sh, sim.sh
├── paper/               # IEEE WinTechCon LaTeX source
└── .devcontainer/       # GitHub Codespaces → OpenROAD environment
```

---

## Verified Contributions

| Contribution | Module | Testbench | Status |
|:-------------|:-------|:---------|:-------|
| SA-ADC (adaptive resolution) | `rtl/sa_adc/sa_adc_controller.v` | `tb/tb_sa_adc_controller.v` | ✅ Verified |
| DECDE-Fusion (direction-aware, windowed) | `rtl/decde/fusion_unit.v` | `tb/tb_fusion.v` | ✅ Verified |
| CSA (ΣW=64 invariant, saturation) | `rtl/csa/crop_stress_accelerator.v` | `tb/tb_csa.v` | ✅ Verified |
| Decision Tree (7-node, programmable) | `rtl/dt/decision_tree_accelerator.v` | `tb/tb_dt.v` | ✅ Verified |
| IPM FSM (4-state, 2-cycle hysteresis) | `rtl/ipm/ipm_fsm.v` | `tb/tb_ipm_fsm.v` | ✅ Verified |
| Weight Calibration (ΣW checker) | `rtl/common/register_file.v` | `tb/tb_top.v` | ✅ Verified |
| Full System (6 scenarios) | `rtl/top/agrisense_ipms_top.v` | `tb/tb_top.v` | ✅ Verified |
| Dwell-Time Analysis (Contribution #3) | — | `tb/tb_dwell_report.v` | ✅ Verified |

---

## Quickstart — Vivado Simulation

```bash
# Compile all RTL + testbenches
E:/Xilinx/Vivado/2024.1/bin/xvlog.bat -i rtl/common \
  rtl/common/isolation_cell.v rtl/common/reg_bus_interconnect.v \
  rtl/common/register_file.v rtl/common/synchronizer.v \
  rtl/decde/ema_filter.v rtl/decde/crossover_detector.v \
  rtl/decde/decde_channel.v rtl/decde/fusion_unit.v \
  rtl/csa/weighted_sum.v rtl/csa/normalization_unit.v \
  rtl/csa/crop_stress_accelerator.v \
  rtl/dt/decision_tree_accelerator.v \
  rtl/ipm/ipm_fsm.v rtl/ipm/power_controller.v rtl/ipm/wake_controller.v \
  rtl/sa_adc/sa_adc_controller.v \
  rtl/top/agrisense_ipms_top.v \
  tb/tb_top.v

# Elaborate and run top-level regression (6 scenarios)
E:/Xilinx/Vivado/2024.1/bin/xelab.bat -top tb_top -snapshot tb_top_snap
E:/Xilinx/Vivado/2024.1/bin/xsim.bat tb_top_snap -runall

# Generate synthetic sensor traces
python sim/scripts/generate_traces.py
```

---

## Quickstart — OpenROAD Synthesis (GitHub Codespaces)

```bash
# Open in Codespaces (pre-configured with OSS-CAD-Suite)
# Click: Code → Codespaces → Create codespace on main

# Inside codespace:
cd synth/openlane/ipm
yosys synth_ipm.tcl
# Reports: Area, Power, Cell Count, Timing

cd ../top
yosys synth_top.tcl
```

---

## Register Map Summary

| Range | Block | Key Registers |
|:------|:------|:-------------|
| `0x00–0x0F` | SIE | Sensor readings (RO) |
| `0x10–0x1F` | CSA | Weights + ΣW status (`0x1A`) |
| `0x20–0x4F` | DECDE | EMA shift factors |
| `0x50–0x5F` | Fusion | Window, vote threshold, pattern (`0x55–0x56`) |
| `0x60–0x7F` | Decision Tree | Thresholds T0–T6, leaf output |
| `0x80–0x9F` | SA-ADC | Per-channel T1/T2, battery thresholds |
| `0xA0–0xAF` | IPM | FSM state, enable bits |

---

## Citation

```bibtex
@inproceedings{agrisense_ipms_2026,
  title     = {AgriSense-IPMS: A Hierarchical Wake Pipeline ASIC for Energy-Efficient Crop Stress Monitoring},
  author    = {Niranjan B., Aashish},
  booktitle = {Proceedings of WinTechCon 2026},
  year      = {2026}
}
```
