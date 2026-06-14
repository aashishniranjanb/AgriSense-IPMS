# AgriSense-IPMS Tapeout & Validation Roadmap

This document outlines the development roadmap for the AgriSense-IPMS chip from functional verification to layout signoff.

---

## Phase 1: Functional Verification (Stage A - RTL v1.0)
*   **Status:** **Completed**
*   **Milestones:**
    *   [x] Context-Aware SA-ADC Controller implementation (`sa_adc_controller.v`).
    *   [x] Temporal correlation crossover window logic in Fusion Unit (`fusion_unit.v`).
    *   [x] Normalization shift unit with programmable register override in CSA (`normalization_unit.v`).
    *   [x] Decision Tree severity/type split format (`decision_tree_accelerator.v`).
    *   [x] System integration and multi-scenario verification (`tb_top.v`).
    *   [x] Zero lint warnings and clean simulation regressions under Vivado Simulator.

---

## Phase 2: OpenROAD ASIC Physical Design (Stage B - Sky130HD)
*   **Status:** **Planned / In-Progress**
*   **Milestones:**
    *   [ ] Run block-level synthesis sweeps (Yosys) to generate cell-count and area reports for individual blocks (CSA, DECDE, Fusion, Decision Tree, SA-ADC).
    *   [ ] Configure top-level floorplanning and constraints (OpenLane / Sky130HD PDK).
    *   [ ] Set target clock frequency conservative at $25 - 50\text{ MHz}$ to minimize dynamic power.
    *   [ ] Run Placement & Clock Tree Synthesis (CTS).
    *   [ ] Complete routing (TritonRoute) and verify zero DRC / LVS violations.
    *   [ ] Export GDSII layout database.
    *   [ ] Extract gate-level timing and activity-driven dynamic power metrics from VCD file.

---

## Phase 3: Commercial Fab Signoff (Stage C - Cadence 90nm PDK)
*   **Status:** **Planned**
*   **Milestones:**
    *   [ ] Import finalized Verilog RTL into Cadence Genus for synthesis against 90nm commercial PDK.
    *   [ ] Define physical power domains using Unified Power Format (UPF) for physical gating of Domain 2 and Domain 3.
    *   [ ] Place-and-Route (Innovus) with sleep-transistor cells and isolation clamp cells.
    *   [ ] Perform signoff DRC/LVS and parasitics-based post-layout timing analysis.
