# AgriSense-IPMS Design Decisions

This document details the architectural decisions, design considerations, and implementation trade-offs made in the design of the AgriSense-IPMS processor v1.0.

---

## 1. Hardware weight sum validation ($\Sigma W = 64$)

### Problem
The Crop Stress Accelerator (CSA) calculates the stress score using a weighted sum of five sensor inputs:
$$\text{stress\_score} = \frac{\sum (W_i \times S_i)}{64}$$

This division is implemented as a simple bitwise right-shift of 6 (`weighted_sum[17:6]`) to avoid the high area and power costs of a hardware divider. However, this normalization scheme strictly assumes that the sum of the five weights ($W_{\text{moisture}}, W_{\text{leaftemp}}, W_{\text{humidity}}, W_{\text{airtemp}}, W_{\text{light}}$) is exactly 64.
If the host CPU programs weights that sum to less or more than 64:
- The stress score will scale incorrectly, either shrinking the usable range or causing premature saturation.
- Downstream blocks, including the SA-ADC threshold tables and the Decision Tree thresholds, will become unreachable or miscalibrated, causing silent system failure.

### Solution
An 11-bit adder tree is implemented in the Always-On register file to continuously sum the five 8-bit weight registers. The sum is compared against the constant `11'd64`, and the resulting single-bit status flag `weights_valid` is exposed via the Read-Only register `REG_WEIGHT_STATUS` (`0x1A`). 
- **11-bit Precision:** Five 8-bit operands can sum to at most $255 \times 5 = 1275$, which requires an 11-bit representation. Using a lower bitwidth (e.g. 9 bits) is vulnerable to silent wrapping (e.g. a sum of $512 + 64 = 576$ would wrap to 64 and falsely validate the weights).
- **Host Pre-flight Check:** The host controller or test harness checks this bit prior to enabling the CSA or running agricultural traces.

---

## 2. Direction-Aware Temporal Crossover Fusion

### Problem
Single-cycle digital crossover detection (identifying when a sensor's Fast EMA crosses its Slow EMA) is highly sensitive to noise and channel-to-channel phase lags. To address this, a sliding temporal "sticky window" is used to latch crossovers for `window_size` cycles.
However, a simple count of recent crossovers is direction-agnostic. For example, two channels crossing in the *same* direction (e.g., both rising) could indicate a generic environmental shift or calibration drift. Agronomic stress events are typically defined by specific multi-directional trends—for instance, soil moisture falling *while* leaf temperature rises.

### Solution
We extended the Fusion Unit to perform **direction-aware temporal correlation**:
- **Programmable Pattern Register:** A 10-bit R/W register `REG_FUSION_PATTERN` (spread across addresses `0x55` and `0x56`) encodes the target direction for each of the 5 channels using 2 bits per channel:
  - `00` = Don't Care (any crossover counts)
  - `01` = Rising Required (crossover must occur on a rising trend: Fast > Slow)
  - `10` = Falling Required (crossover must occur on a falling trend: Fast < Slow)
  - `11` = Excluded (crossover on this channel is ignored)
- **Qualified Voting:** Inside the sliding window, the crossover's direction is latched alongside its active flag. Only crossovers matching the programmed pattern are considered "qualified" and summed toward the `fusion_score`.
- This ensures the novelty claim of "correlated crop stress identification" aligns with the hardware implementation, eliminating false-alarm events from irrelevant environmental drifts.

---

## 3. Warning-Exit Hysteresis (Anti-Thrashing)

### Problem
AgriSense-IPMS employs a Hierarchical Wake Pipeline to conserve energy by keeping high-performance domains (Domain 2 for the CSA and Decision Tree, Domain 3 for the LoRa transceiver) powered off or isolated during nominal conditions.
- **Fusion Unit:** Trend-based leading indicator, triggering a transition from `MONITOR` to `WARNING`.
- **Decision Tree:** Level-based lagging indicator, evaluating absolute stress severity to guide state transitions.

During the onset of crop stress, the trend detector (Fusion) may fire a `stress_event`, waking Domain 2. However, the absolute sensor levels may not have crossed the Decision Tree's thresholds yet, resulting in a `NORMAL` (00) severity reading. Without hysteresis, the IPM FSM would immediately drop back to `MONITOR` (turning off Domain 2), only for the Fusion unit to re-trigger a few cycles later as the trend continues. 
This produces rapid power-up/down thrashing of Domain 2, whose switching energy and settling time overhead would quickly exceed any power savings of the sleep states.

### Solution
A 2-bit sequential exit counter (`exit_ctr`) is integrated within `ipm_fsm.v`.
- When in `WARNING` state, the FSM requires exactly **2 consecutive cycles** of `NORMAL` severity (`leaf_output[3:2] == 2'b00`) before transitioning back to `MONITOR`.
- Any non-normal severity level resets `exit_ctr` to 0.
- This creates an algorithmic debounce filter, ensuring that transient noise or expected transient disagreements between the trend and level detectors do not cause power-grid thrashing.
