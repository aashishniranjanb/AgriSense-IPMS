# AgriSense-IPMS

## Architecture Overview
Sensors -> SA-ADC -> DECDE-Fusion -> Decision Tree -> IPM -> LoRa Alert

### Contributions
1. **Stress-Aware Adaptive ADC (SA-ADC):** More accuracy only when needed (8-bit, 10-bit, 12-bit).
2. **Multi-Channel DECDE-Fusion Event Detection:** Fast and slow EMA filters to detect crossover trends before severe stress.
3. **Hierarchical Wake Pipeline (Decision Tree + IPM):** Wakes up the system from NORMAL -> WARNING -> CRITICAL states.

## Roadmap
- Phase 1: Register File + Definitions
- Phase 2: DECDE Channel
- Phase 3: Fusion Unit
- Phase 4: SA-ADC
- Phase 5: CSA
- Phase 6: Decision Tree
- Phase 7: IPM FSM
- Phase 8: Top-Level Integration
- Phase 9: Verilator Simulation
- Phase 10: OpenROAD Synthesis
