# AgriSense-IPMS Register Map

This document defines the 256-byte register file configuration map for the AgriSense-IPMS architecture. 

## Overview
The register map is the chip's "control panel." All configuration registers (weights, thresholds, modes) and status registers reside here in the **Always-On Domain**. This prevents configuration loss when other domains (Domain 2 or 3) are powered down.

| Address Range | Module | Description |
|---|---|---|
| `0x00 - 0x0F` | **SIE** | Sensor Interface Engine configs and readings |
| `0x10 - 0x1F` | **CSA** | Crop Stress Accelerator weights and score |
| `0x20 - 0x4F` | **DECDE** | Dynamic Event-Driven Crossover Detection Engine |
| `0x50 - 0x5F` | **Fusion** | Fusion Unit flags and outputs |
| `0x60 - 0x7F` | **Decision Tree** | Decision Tree nodes and thresholds |
| `0x80 - 0x9F` | **SA-ADC** | Stress-Aware ADC thresholds and modes |
| `0xA0 - 0xAF` | **IPM** | Intelligent Power Manager state and enables |

## Detailed Map

### SIE (0x00 - 0x0F)
| Address | Name | Type | Description |
|---|---|---|---|
| `0x00` | `SENSOR_ENABLE` | R/W | Bitmask to enable sensors |
| `0x01` | `SENSOR_SELECT` | R/W | Active sensor selection |
| `0x02` | `SENSOR_STATUS` | RO | Status of sensor readings |
| `0x04` | `MOISTURE` | RO | Current Moisture reading |
| `0x05` | `LEAF_TEMP` | RO | Current Leaf Temperature reading |
| `0x06` | `HUMIDITY` | RO | Current Humidity reading |
| `0x07` | `AIR_TEMP` | RO | Current Air Temperature reading |
| `0x08` | `LIGHT` | RO | Current Light reading |
| `0x09` | `BATTERY` | RO | Current Battery reading |

### CSA (0x10 - 0x1F)
| Address | Name | Type | Description |
|---|---|---|---|
| `0x10` | `W_MOISTURE` | R/W | Moisture weight |
| `0x11` | `W_LEAFTEMP` | R/W | Leaf Temperature weight |
| `0x12` | `W_HUMIDITY` | R/W | Humidity weight |
| `0x13` | `W_AIRTEMP` | R/W | Air Temperature weight |
| `0x14` | `W_LIGHT` | R/W | Light weight |
| `0x18` | `STRESS_SCORE` | RO | Calculated stress score |
| `0x19` | `CSA_SCALE_FACTOR` | R/W | Normalization shift factor (default 6, i.e., divide by 64) |

### DECDE (0x20 - 0x4F)
| Address | Name | Type | Description |
|---|---|---|---|
| `0x20` | `SHIFT_FACTOR_0` | R/W | Moisture shift factor |
| `0x21` | `SHIFT_FACTOR_1` | R/W | Leaf Temp shift factor |
| `0x22` | `SHIFT_FACTOR_2` | R/W | Humidity shift factor |
| `0x23` | `SHIFT_FACTOR_3` | R/W | Air Temp shift factor |
| `0x24` | `SHIFT_FACTOR_4` | R/W | Light shift factor |

### Fusion (0x50 - 0x5F)
| Address | Name | Type | Description |
|---|---|---|---|
| `0x50` | `CROSS_FLAG_VECTOR` | RO | Crossover flags from DECDE |
| `0x51` | `WINDOW_SIZE` | R/W | Fusion window size |
| `0x52` | `VOTE_THRESHOLD` | R/W | Minimum flags required for event |
| `0x53` | `FUSION_SCORE` | RO | Computed fusion score |
| `0x54` | `STRESS_EVENT` | RO | 1 if stress event detected |

### Decision Tree (0x60 - 0x7F)
| Address | Name | Type | Description |
|---|---|---|---|
| `0x60` | `T0` | R/W | Node 0 Threshold (Stress Score) |
| `0x61` | `T1` | R/W | Node 1 Threshold (Fusion Score) |
| `0x62` | `T2` | R/W | Node 2 Threshold (Moisture) |
| `0x63` | `T3` | R/W | Node 3 Threshold (LeafTemp) |
| `0x64` | `T4` | R/W | Node 4 Threshold (Humidity) |
| `0x65` | `T5` | R/W | Node 5 Threshold (AirTemp) |
| `0x66` | `T6` | R/W | Node 6 Threshold (Light) |
| `0x70` | `LEAF_OUTPUT` | RO | Tree Classification Output: [7:6] type, [5:2] zeros, [1:0] severity |

### SA-ADC (0x80 - 0x9F)
| Address | Name | Type | Description |
|---|---|---|---|
| `0x80` | `MOISTURE_T1` | R/W | Moisture Threshold 1 |
| `0x81` | `MOISTURE_T2` | R/W | Moisture Threshold 2 |
| `0x82` | `LEAF_T1` | R/W | Leaf Threshold 1 |
| `0x83` | `LEAF_T2` | R/W | Leaf Threshold 2 |
| `0x84` | `HUMIDITY_T1` | R/W | Humidity Threshold 1 |
| `0x85` | `HUMIDITY_T2` | R/W | Humidity Threshold 2 |
| `0x86` | `AIRTEMP_T1` | R/W | Air Temperature Threshold 1 |
| `0x87` | `AIRTEMP_T2` | R/W | Air Temperature Threshold 2 |
| `0x88` | `LIGHT_T1` | R/W | Light Threshold 1 |
| `0x89` | `LIGHT_T2` | R/W | Light Threshold 2 |
| `0x8A` | `B_CRIT` | R/W | Battery Critical Threshold |
| `0x8B` | `B_LOW` | R/W | Battery Low Threshold |
| `0x8C` | `ADC_MODE_LSB` | RO | ADC Resolution Mode LSB (Moisture[1:0], Leaf[3:2], Humidity[5:4], AirTemp[7:6]) |
| `0x8D` | `ADC_MODE_MSB` | RO | ADC Resolution Mode MSB (Light[1:0] in bits [1:0]) |

### IPM (0xA0 - 0xAF)
| Address | Name | Type | Description |
|---|---|---|---|
| `0xA0` | `STATE` | RO | Current FSM State (SLEEP, MONITOR, WARNING, CRITICAL) |
| `0xA1` | `ENABLES` | RO | Active Power Domain Enables |
| `0xA2` | `BATTERY_LEVEL` | RO | Readout of Battery |
