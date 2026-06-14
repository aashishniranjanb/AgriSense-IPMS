# Architecture Comparison Table

This table compares the architectural traits and design metrics of **AgriSense-IPMS** against conventional duty-cycled sensor nodes and the reference **SamurAI** wake-up system.

| Design | Power Profile | Area Overhead | Wake Latency | ADC Resolution Strategy |
| :--- | :--- | :--- | :--- | :--- |
| **Conventional Duty-Cycled Node** | High active burst power; constant background leakage due to periodic timer wakes. | Base sensor nodes. | High (up to full wake interval period, e.g., minutes). | Static 12-bit resolution always (no context adaptation). |
| **SamurAI (Qualitative Ref)** | Low (wake-up receiver gated), but high compute overhead when active. | Medium-high (requires integrated neural engines/memory). | Low (event-driven). | Fixed or basic threshold-based switching. |
| **AgriSense-IPMS (This Work)** | Ultra-Low (hierarchical gating: event-driven wake of accelerators and radio). | Tiny (<50 kGE, fully combinational comparator/shift-add paths). | Sub-microsecond (immediate wakeup on trend crossover). | **Stress-Aware Adaptive Resolution** (8/10/12-bit adaptive context escalation + battery capping). |

---

## Quantitative Platform Benchmarking Comparison

The following table compares the physical implementation and performance metrics of the proposed AgriSense-IPMS ASIC against standard microcontroller (MCU) and FPGA-based telemetry configurations for precision agriculture:

| Platform | Core Silicon Area | Nominal Frequency | Power Consumption | Key Characteristics / Architectural Traits |
| :--- | :---: | :---: | :---: | :--- |
| **STM32 MCU** | N/A | 80 MHz | >100.0 mW | Software polling loop; high constant active power overhead. |
| **FPGA Implementation** | Large | 100–150 MHz | >200.0 mW | High static routing leakage; generic lookup-table mapping. |
| **Proposed ASIC** | **0.143 mm²** | **116.15 MHz** | **34.1 mW** | **Event-driven domain gating; dedicated hardware accelerators.** |

*Note: Microcontroller and FPGA estimates are derived from literature baselines under equivalent telemetry work cycles. AgriSense-IPMS metrics represent post-PnR signoff numbers on the Sky130HD PDK.*

