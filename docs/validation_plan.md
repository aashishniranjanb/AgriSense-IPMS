# AgriSense-IPMS Validation Plan

This document details the validation strategy, test datasets, and evaluation metrics used to verify the AgriSense-IPMS ASIC design across all development phases.

---

## 1. Multi-Stage Validation Pipeline

### Stage A: Functional Verification (Verilog / Verilator)
*   **Objective:** Confirm cycle-accurate logical correctness.
*   **Flow:**
    1.  Execute block-level unit testbenches (EMA, DECDE, Fusion, CSA, Decision Tree, SA-ADC, RegFile).
    2.  Run top-level system testbench (`tb_top.v`) simulating the 6 core scenarios representing Nominal -> Water Stress -> Correlation -> Wakeup -> Classification -> Recovery.
    3.  Generate Value Change Dump (`.vcd`) waveform traces to debug timing.
    4.  Verify that no `X` or `Z` propagation occurs at reset.

### Stage B: Synthesis-Level Validation (OpenROAD / Sky130)
*   **Objective:** Synthesize the design to evaluate timing, area, and dynamic power under physical gates.
*   **Flow:**
    1.  Compile Verilog RTL using Yosys through the OpenLane/OpenROAD flow.
    2.  Generate gate-level netlists.
    3.  Run static timing analysis (STA) to confirm zero setup/hold slack violations.
    4.  Utilize activity-driven power reports (.vcd fed into OpenROAD) to verify the dynamic power savings achieved by input-gating Domain 2 and Domain 3.

### Stage C: Tapeout-Ready Validation (Cadence 90nm SS PDK)
*   **Objective:** Verify post-layout timing and physical constraints.
*   **Flow:**
    1.  Run Cadence Genus for synthesis using the 90nm standard cell library.
    2.  Use Innovus for physical floorplanning, routing, and power-grid routing (with UPF defining Domain 2/3 power routing).
    3.  Perform Layout vs. Schematic (LVS) and Design Rule Checking (DRC) to ensure tapeout readiness.

---

## 2. Validation Datasets

Validation traces are generated synthetically using `sim/scripts/generate_traces.py`. The resulting files are stored under `sim/traces/`:

| Dataset File | Scenario Target | Agricultural Description |
|:---|:---|:---|
| `baseline_diurnal.csv` | Nominal Conditions | Standard diurnal changes in temperature and light. Moisture remains constant. No crossovers should occur. |
| `correlated_stress_01.csv` | Water Stress | Steady decline in soil moisture with rising leaf temperature, leading to a correlated warning state. |
| `correlated_stress_02.csv` | Thermal Stress | Rapid increase in air/leaf temperatures during a heatwave. |
| `correlated_stress_03.csv` | Multi-Factor Event | Staggered moisture drop, humidity drop, and light spike. Tests temporal windowing in the Fusion Unit. |
| `heterogeneous_field.csv` | Spatial Diversity | Random variations across sensors to test noise suppression and threshold margins. |
| `homogeneous_field.csv` | Field Baseline | Clean baseline testing of multiple sensors behaving identically. |

---

## 3. Evaluation Metrics

### 1. Detection Latency (cycles)
*   *Definition:* The number of clock cycles between the physical sensor crossing a threshold and the FSM transitioning to `IPM_WARNING` or `IPM_CRITICAL`.
*   *Target:* $< 15$ cycles under all correlated stress scenarios.

### 2. Crossover Window Sensitivity
*   *Definition:* The ability of the Fusion Unit's sliding window (`WINDOW_SIZE`) to successfully correlate staggered crossovers.
*   *Metric:* Sensitivity = $\text{True Positives} / (\text{True Positives} + \text{False Negatives})$.
*   *Target:* $100\%$ detection of events where sensor crossings occur within `WINDOW_SIZE` cycles.

### 3. Dynamic Power Reduction (%)
*   *Definition:* The ratio of dynamic power consumed when Domain 2/3 are active vs. when Domain 2/3 are gated.
*   *Formula:*
    $$\text{Savings} = 1 - \frac{P_{\text{sleep}}}{P_{\text{active}}}$$
*   *Target:* $>80\%$ reduction in compute dynamic switching power when Domain 2 is sleeping.

### 4. Gate Count and Area (kGE / $\mu m^2$)
*   *Definition:* Overall area footprint of the synthesized design.
*   *Target:* $< 50\text{ kGE}$ (kilo-Gate Equivalents) to satisfy the constraint for cost-sensitive agricultural sensor nodes.
