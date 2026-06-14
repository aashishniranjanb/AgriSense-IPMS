# Architecture Comparison Table

This table compares the architectural traits and design metrics of **AgriSense-IPMS** against conventional duty-cycled sensor nodes and the reference **SamurAI** wake-up system.

| Design | Power Profile | Area Overhead | Wake Latency | ADC Resolution Strategy |
| :--- | :--- | :--- | :--- | :--- |
| **Conventional Duty-Cycled Node** | High active burst power; constant background leakage due to periodic timer wakes. | Base sensor nodes. | High (up to full wake interval period, e.g., minutes). | Static 12-bit resolution always (no context adaptation). |
| **SamurAI (Qualitative Ref)** | Low (wake-up receiver gated), but high compute overhead when active. | Medium-high (requires integrated neural engines/memory). | Low (event-driven). | Fixed or basic threshold-based switching. |
| **AgriSense-IPMS (This Work)** | Ultra-Low (hierarchical gating: event-driven wake of accelerators and radio). | Tiny (<50 kGE, fully combinational comparator/shift-add paths). | Sub-microsecond (immediate wakeup on trend crossover). | **Stress-Aware Adaptive Resolution** (8/10/12-bit adaptive context escalation + battery capping). |
