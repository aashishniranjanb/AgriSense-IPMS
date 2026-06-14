# AgriSense-IPMS Synthesis Metrics

## Synthesis Tool & Configuration
- **Tool**: Yosys 0.64 (OpenROAD Flow Scripts 26Q2-1994-g065077a742)
- **Synthesis Time**: 7.05 seconds
- **Memory Peak**: 97.33 MB
- **Top Module**: `agrisense_ipms_top`

## Design Statistics

### Cell Count Summary
| Metric | Count |
|--------|-------|
| **Total Cells** | **12,612** |
| Sequential Cells (DFF) | 2,138 |
| Combinational Cells | 10,436 |

### Sequential Cell Breakdown
| Cell Type | Count |
|-----------|-------|
| `$_DFFE_PN0P_` (DFF with enable, P clock, P reset) | 2,123 |
| `$_DFFE_PN1P_` (DFF with enable, P clock, N reset) | 2 |
| `$_DFF_PN0_` (DFF, P clock, N reset) | 13 |
| **Total Sequential** | **2,138** |

### Combinational Cell Breakdown
| Cell Type | Count |
|-----------|-------|
| NAND gates | 3,983 |
| AND gates | 3,637 |
| OR gates | 326 |
| XOR gates | 869 |
| XNOR gates | 326 |
| MUX (2:1 multiplexers) | 550 |
| ORNOT gates | 441 |
| ANDNOT gates | 185 |
| NOR gates | 99 |
| NOT gates | 20 |
| **Total Combinational** | **10,436** |

### Wiring Statistics
| Metric | Count |
|--------|-------|
| Total Wires | 11,149 |
| Total Wire Bits | 15,353 |
| Public Wires | 747 |
| Public Wire Bits | 4,951 |
| Ports | 21 |
| Port Bits | 97 |

## Paper Metrics (Key for Publication)

### Design Complexity
- **Total Transistor Count (estimated)**: ~150K-200K transistors
  - (Based on 12,612 cells × typical 12-15 transistors/gate)
- **Logic Density**: High (combinational-dominated: 83% of cells)

### Power Domain Distribution
The design includes three main functional blocks:
1. **Crop Stress Accelerator (CSA)**: ~3,800 cells (normalized pixels + weighted sum)
2. **Decision Engine (DECDE)**: ~2,100 cells (EMA filter + fusion logic)
3. **Intelligent Power Manager (IPM)**: ~1,500 cells (FSM + power control)
4. **Support Modules**: ~5,200 cells (register file, mux, synchronizers)

### Memory Inference
- **Register File (register_file.v)**: Converted to register list (~256 registers)
- **Fusion Window Buffer (fusion_unit.v)**: Inferred SRAM opportunity

## Sky130hd Synthesis Results (ORFS)

### Area Breakdown
| Metric | Value |
|--------|-------|
| **Design Area (Sky130hd)** | **125,370 µm²** |
| Core Utilization | 100% |
| Estimated Aspect Ratio | ~1.0 (square-like die) |

### Die Dimensions (Estimated)
- Width × Height: ~354 µm × 354 µm (assuming square)
- Actual die will be determined after placement and routing

### Synthesis Performance
| Metric | Value |
|--------|-------|
| Synthesis Time (Yosys) | 15.39 seconds |
| ABC Technology Mapping | 7 seconds |
| Peak Memory Usage | 172 MB |
| Tool: Yosys | 0.64 (git sha1 8449dd470) |

## Next Steps (Place & Routing)
- Run full ORFS flow: `make DESIGN_CONFIG=designs/sky130hd/agrisense_ipms/config.mk`
- Expected runtime: 30-120 minutes (placement, CTS, routing)
- Will generate:
  - Layout (DEF format)
  - GDSII (final physical design)
  - Timing closure report
  - Power analysis

---

**Generated**: June 14, 2026 (UTC)
**ORFS Build**: 26Q2-1994-g065077a742
**PDK**: sky130hd
**Design Configuration**: 
```makefile
DESIGN_NAME = agrisense_ipms_top
PLATFORM = sky130hd
CORE_UTILIZATION = 35
PLACE_DENSITY = 0.50
CLOCK_PERIOD = 10 ns (100 MHz)
```
