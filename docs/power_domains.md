# AgriSense-IPMS Power Domain Specification

## Overview
To achieve ultra-low power consumption, the AgriSense-IPMS architecture is divided into three hierarchically gated power domains. Waking up high-power blocks occurs sequentially in response to detected environmental stress.

```
+-----------------------------------------------------------------+
|                   Domain 1: Always-On Domain                    |
|  - Register File (Always-On Registers)                          |
|  - Host Bus Interface (reg_bus_interconnect)                    |
|  - IPM FSM System Controller                                    |
|  - Sensor Interface Engine (SIE) & SA-ADC resolution control     |
|  - DECDE Filtering Channels (EMA Filters & Crossover Detectors)  |
|  - Fusion Unit (Temporal Windows & Event Voting)                |
+-----------------------------------------------------------------+
                                |
                   (Wakes up Domain 2 on STRESS_EVENT)
                                v
+-----------------------------------------------------------------+
|                     Domain 2: Compute Domain                    |
|  - Crop Stress Accelerator (CSA weighted sum)                   |
|  - Decision Tree Accelerator (3-depth classification)           |
+-----------------------------------------------------------------+
                                |
               (Wakes up Domain 3 on CRITICAL_STRESS or type >= 4)
                                v
+-----------------------------------------------------------------+
|                   Domain 3: Communication Domain                |
|  - LoRa Packet Formatter                                        |
|  - LoRa SPI Transceiver Interface (SX1276 Master)               |
+-----------------------------------------------------------------+
```

---

## Power Domain Toolchain Mapping (Stage A / B / C Plan)

The power management architecture transitions through three stages of validation and physical toolchain flows:

### 1. Stage A: Functional Simulation (Vivado / Verilator)
*   **Approach:** Gated inputs and behavioral models of isolation cells.
*   **Details:** 
    *   To prevent dynamic power toggling in functional simulators, inputs to disabled modules (e.g., `sample_valid` to the DECDE channel) are gated combinationally with their enable signals.
    *   Outputs from Domain 2 are routed through `power_controller.v` where `isolation_cell` modules clamp values to zero when `domain2_pwr_en` is low. This prevents undefined/garbage outputs from propagating when the domain is "asleep".

### 2. Stage B: Synthesis & Physical Flow (OpenROAD / Sky130)
*   **Approach:** Activity-Based Gating & Dynamic Power Minimization.
*   **Details:**
    *   Standard OpenROAD configurations under Sky130 typically map designs to a single global power grid. Physical power switches (power gating) are complex to configure automatically in the open-source flow.
    *   Therefore, for Stage B, power reduction is framed as **activity-based dynamic-power reduction**. Gating the inputs of the CSA and Decision Tree accelerators to constant zeros when `csa_en` and `dtree_en` are low eliminates signal switching activity, which OpenROAD timing/power reports can measure directly.
    *   Isolation cells act as structural buffers that ensure these static networks remain quiet.

### 3. Stage C: Custom ASIC Tapeout Flow (Cadence 90nm / Synopsys UPF)
*   **Approach:** Physical Multi-Voltage Power Gating with UPF/CPF.
*   **Details:**
    *   This stage implements true power-gating switches in the silicon layout.
    *   A Unified Power Format (UPF) file defines the power domains (`VDD_AON` for Domain 1, `VDD_COMP` for Domain 2, and `VDD_COMM` for Domain 3).
    *   Physical headers/footers (sleep transistors) gate the ground rails (`VSS`) or power rails (`VDD`) of Domain 2 and Domain 3.
    *   Isolation cells are mapped to hardware standard cells (e.g., ISO-AND, ISO-OR) connected to the always-on power grid, preventing sneak leakage paths when domains are powered down.

---

## Isolation Strategy & Net Boundaries

When Domain 2 is powered off, its outputs would physically float in a real chip, causing excessive leakage current at the inputs of Domain 1 modules. To prevent this, isolation cells gate these nets:

1.  **CSA Output (`stress_score`):**
    *   *Path:* Domain 2 -> Domain 1 (Register File status register `0x18`) and Domain 2 (Decision Tree Node 0).
    *   *Control:* Gated by `!domain2_pwr_en`. When low, clamps `stress_score_iso` to `8'd0`.
2.  **Decision Tree Output (`leaf_output`):**
    *   *Path:* Domain 2 -> Domain 1 (Register File status register `0x70` and IPM FSM input).
    *   *Control:* Gated by `!domain2_pwr_en`. When low, clamps `leaf_output_iso` to `4'b0000` (NORMAL).
3.  **Communication Enable (`comm_en_out`):**
    *   *Path:* Domain 1 -> Domain 3.
    *   *Control:* Handled by the IPM FSM directly in Domain 1 (Always-On) to ensure Domain 3 wakes up cleanly.
