# Decision Tree Accelerator Architecture Specification
**Status:** Frozen (Phase 6A)

## 1. Overview
The Decision Tree Accelerator is the final classification stage of Domain 2. It acts to classify crop stress using raw sensors, the CSA stress score, and the DECDE fusion score, to generate an actionable stress state.

## 2. Architectural Rules
- **Execution:** Purely Combinational. No state, no FSMs, no accumulators. Wakes up, evaluates, sleeps.
- **Topology:** Balanced Binary Tree.
- **Depth:** 3.
- **Nodes:** 7 Comparator Nodes.
- **Leaves:** 8 Output Classifications.

## 3. Inputs
- **Sensors:** `[7:0] moisture`, `[7:0] leaf_temp`, `[7:0] humidity`, `[7:0] air_temp`, `[7:0] light`
- **Scores:** `[7:0] stress_score`, `[2:0] fusion_score`
- **Control:** `stress_event` (Tree evaluation enable)

## 4. Comparator Node Mapping
Feature selection is **hardcoded**, while thresholds are **programmable** via Domain 1 Register File.
- **Node0:** `Stress Score < T0`
- **Node1:** `Fusion Score < T1`
- **Node2:** `Moisture < T2`
- **Node3:** `LeafTemp < T3`
- **Node4:** `Humidity < T4`
- **Node5:** `AirTemp < T5`
- **Node6:** `Light < T6`

## 5. Leaf Output Encoding
Leaf classifications focus on defensible, sensor-driven states:
- `3'b000` : `NORMAL`
- `3'b001` : `LOW_STRESS`
- `3'b010` : `MODERATE_STRESS`
- `3'b011` : `HIGH_STRESS`
- `3'b100` : `CRITICAL_STRESS`
- `3'b101` : `WATER_DOMINANT`
- `3'b110` : `TEMP_DOMINANT`
- `3'b111` : `MULTI_FACTOR_EVENT`
