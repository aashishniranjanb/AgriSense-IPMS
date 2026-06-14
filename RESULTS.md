# AgriSense-IPMS ASIC Physical Implementation Results

This document summarizes the final place-and-route (PnR) signoff metrics and physical layout statistics for **AgriSense-IPMS** (v1.0) on the **SkyWater 130nm High-Density (Sky130HD)** technology node.

---

## 1. System & Physical Design Status

The design has successfully completed the full open-source RTL-to-GDSII ASIC implementation flow using the OpenLane/OpenROAD toolchain. The layout is fully verified and clean:

*   **ASIC Synthesis:** Passed cleanly with zero latches and verified memory-inference logic.
*   **Floorplanning & Placement:** Successfully bound to a square core footprint with a target core utilization of **39.5%**.
*   **Timing Optimization & CTS:** Achieved timing closure with zero setup/hold violations.
*   **Routing & Signoff:** Routing completed with exactly **0 DRC** and **0 Antenna** violations.
*   **GDSII Generation:** Successfully stream-out final tapeout-ready databases (`6_final.gds`).

---

## 2. Final Signoff Metrics

The key post-routing physical design and timing closure metrics are summarized in the table below:

| Parameter | Value | Description |
| :--- | :---: | :--- |
| **Technology** | SkyWater 130nm HD | Target physical cell library |
| **Design Core Area** | 143,334 $\mu m^2$ | Active silicon core boundary ($0.143\text{ mm}^2$) |
| **Core Utilization** | 39.5% | Standard cell placement density |
| **Max Frequency ($F_{max}$)** | 116.15 MHz | Achieved operating frequency limit |
| **Minimum Clock Period** | 8.61 ns | Critical path delay limit |
| **Worst Negative Slack (WNS)** | 0.00 ns | Timing closed with zero setup slack violations |
| **Total Negative Slack (TNS)** | 0.00 ns | No setup timing violations on any path |
| **Total Power** | 34.1 mW | Integrated dynamic and static power |
| **Leakage Power** | 71.8 nW | Idle state static leakage power |
| **DRC Violations** | 0 | Design Rule Check signoff status |
| **Antenna Violations** | 0 | Antenna ratio check signoff status |
| **Total Cells** | 58,891 | Integrated cell instances (including filler/taps) |

---

## 3. Power Breakdown

The total chip power of **34.1 mW** at the achieved $F_{max}$ is distributed across functional categories as follows:

| Component | Power | Percentage | Description |
| :--- | :---: | :---: | :--- |
| **Sequential** | 10.3 mW | 30.2% | Flip-Flops and always-on registers |
| **Combinational** | 13.8 mW | 40.6% | Arithmetic units (CSA multipliers, DTree) |
| **Clock Network** | 9.97 mW | 29.2% | Clock tree buffers, inverters, and routing load |
| **Leakage** | 71.8 nW | <0.1% | Transistor leakage under nominal conditions |
| **Total** | **34.1 mW** | **100.0%** | **Total signoff power consumption** |

---

## 4. Standard Cell Breakdown

The cell type usage report extracted during the final signoff stage lists instance counts and active silicon area for each standard cell category:

| Cell Category | Instance Count | Total Area ($\mu m^2$) | Description / Function |
| :--- | :---: | :---: | :--- |
| **Fill cell** | 37,269 | 219,730.74 | Density requirements and base filling |
| **Tap cell** | 4,794 | 5,998.25 | Substrate tap cells to prevent latch-up |
| **Antenna cell** | 5 | 12.51 | Gate protection diodes for routing antennas |
| **Clock buffer** | 398 | 7,945.12 | Clock tree branch drivers |
| **Timing repair buffer** | 381 | 3,175.55 | Hold and setup delay buffers |
| **Inverter** | 1,284 | 4,883.43 | Standard signal phase inversions |
| **Clock inverter** | 75 | 928.39 | Clock tree phase inversions |
| **Sequential cell** | 2,157 | 53,980.52 | Registers and memory (Flip-Flops) |
| **Multi-input combinational** | 12,528 | 66,409.94 | Logic gates (AND, OR, MUX, arithmetic) |
| **Total** | **58,891** | **363,064.46** | **Total silicon boundary footprint** |

---

## 5. Benchmarking & Comparison Study

To highlight the energy efficiency of the proposed ASIC architecture, AgriSense-IPMS is benchmarked against standard microcontroller (MCU) and FPGA-based precision agriculture telemetry configurations:

| Platform | Core Area | Max Frequency | Nominal Power | Key Characteristics |
| :--- | :---: | :---: | :---: | :--- |
| **STM32 MCU** | N/A | 80 MHz | >100.0 mW | Software polling loop; high constant active power. |
| **FPGA Implementation** | Large | 100–150 MHz | >200.0 mW | High static routing leakage; generic lookup-table mapping. |
| **Proposed ASIC** | **0.143 mm²** | **116.15 MHz** | **34.1 mW** | **Event-driven domain gating; dedicated hardware accelerators.** |

*Note: Microcontroller and FPGA estimates are derived from literature baselines under equivalent telemetry work cycles. AgriSense-IPMS metrics represent post-PnR signoff numbers.*

---

## 6. Physical Layout Figures

The following layout analysis screenshots are available inside the repository's results directory for publication figures:

*   **Figure 1: System Architecture** (Conceptual diagram detailing sensor interfaces, DECDE trend filters, CSA combinational engines, Decision Tree severity wakes, and the IPM FSM).
*   **Figure 2: Placement Layout** (`paper_results/final_placement.webp` - showing localized density placement).
*   **Figure 3: Clock Tree Layout** (`paper_results/final_clocks.webp` or `cts_default_clk_layout.webp` - showing clock buffer distribution and routing tree).
*   **Figure 4: Routing Layout** (`paper_results/final_routing.webp` or `paper_results/final_all.webp` - showing detailed routing grids).
*   **Figure 5: IR Drop Analysis** (`paper_results/final_ir_drop.webp` - confirming power grid voltage integrity).
*   **Figure 6: Timing Critical Path** (`paper_results/final_worst_path.webp` - showing the worst-case setup timing path through the CSA multiplier array).
*   **Figure 7: Congestion Map** (`paper_results/final_congestion.webp` - showing routing track density).
