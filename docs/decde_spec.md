# DECDE Channel Specification (v1.0)

## Purpose
Detect trend changes using a Fast EMA vs Slow EMA comparison, generating `cross_flag` and `trend_direction` for the Fusion Unit.

## Module Name
`rtl/decde/decde_channel.v`

## Top Level Interface
```verilog
module decde_channel
#(
    parameter SENSOR_ID = 0
)
(
    input wire clk,
    input wire rst_n,

    input wire sample_valid,
    input wire [7:0] sensor_sample,
    input wire [2:0] shift_factor,

    output reg cross_flag,
    output reg trend_direction,
    output wire [2:0] sensor_id
);
```

### Sensor ID Mapping
Frozen assignments:
* `0` = Moisture
* `1` = LeafTemp
* `2` = Humidity
* `3` = AirTemp
* `4` = Light

## Data Format
* **Input Sample:** 8-bit unsigned (Range: 0 → 255)
* **EMA Internal Format:** Q8.8 Fixed Point (16 bits total: 15..8 Integer, 7..0 Fraction)
  * *Example:* Sample = `100` is stored as `100 << 8 = 25600`.

## Internal Registers
* `reg [15:0] fast_ema;`
* `reg [15:0] slow_ema;`
* `reg prev_relation;`
* `reg initialized;`

## Initialization Strategy
Do NOT initialize EMA to zero (causes bad convergence).
Use the **first valid sample** when `sample_valid == 1` and `initialized == 0`:
```verilog
fast_ema <= sample << 8;
slow_ema <= sample << 8;
initialized <= 1;
```

## EMA Equations
Both EMAs follow the equation:
`EMA_new = EMA_old + ((sample - EMA_old) >> k)`

Implementation:
```verilog
delta_fast = sample_fixed - fast_ema;
fast_ema <= fast_ema + (delta_fast >>> k_fast);
```

### Co-Adaptive Time Constants
* `k_fast = shift_factor;`
* `k_slow = shift_factor + 2;`
  * *Monitor Mode:* `k_fast = 5`, `k_slow = 7`
  * *Warning Mode:* `k_fast = 2`, `k_slow = 4`

## Crossover Detection & Trend Direction
* **Relation Signal:** `relation = (fast_ema > slow_ema);`
* **Cross Detection:** Occurs when `relation != prev_relation`. Output `cross_flag = 1` pulses for exactly **one clock cycle**.
* **Trend Direction:**
  * `0 = Falling Trend` (Fast EMA crossed below Slow EMA)
  * `1 = Rising Trend` (Fast EMA crossed above Slow EMA)

## Noise Immunity & Sampling Behavior
* **Noise Immunity:** NONE for v1. Noise suppression belongs in the Fusion unit. DECDE needs a clean baseline.
* **Sampling Behavior:** DECDE only updates when `sample_valid == 1`. Otherwise, hold state.

## Timing Behavior
* **Cycle N:** Sample accepted.
* **Cycle N+1:** EMA updated.
* **Cycle N+2:** Cross detection visible.
*(No pipelining required. This is acceptable.)*

## Verification Plan
The testbench MUST pass the following tests:
1. **Constant:** `50, 50, 50, 50, 50` -> `cross_flag = 0`
2. **Declining Moisture:** `60, 58, 56, 54, 52, 48, 44` -> `1 crossover`
3. **Rising Temperature:** `40, 42, 44, 46, 48, 50, 52` -> `1 crossover`
4. **Random Noise:** `50, 49, 50, 51, 50, 49, 50` -> `No continuous retriggering`
