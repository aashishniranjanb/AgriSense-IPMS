#!/usr/bin/env python3
"""
activity_analysis.py
AgriSense-IPMS — Activity Analysis for Table III (Paper Evidence)

Reads the 4 agricultural trace CSVs and computes:
  - Domain 2 active % (approximated from stress_event rate)
  - Domain 3 active % (CRITICAL state rate)
  - Stress events / hour (at 1 sample/cycle, 100 MHz)
  - Average ADC mode (0=8bit, 1=10bit, 2=12bit)

This generates the numbers for Table III in the paper:
  "Power-Saving Evidence: AgriSense vs. Always-On Baseline"
"""

import csv, os, math

TRACES_DIR = os.path.join(os.path.dirname(__file__), "..", "sim", "traces")
CLOCK_HZ   = 100_000_000  # 100 MHz
SAMPLES_PER_CYCLE = 6     # each send_sample() takes ~6 clock cycles

# Weight and threshold config matching tb_top initialization
W = [13, 13, 13, 13, 12]  # weights sum = 64
SHIFT = 6                  # div 64
VOTE_THRESHOLD = 2
WINDOW_SIZE    = 4
EMA_SHIFT      = 2         # α ≈ 1/4

# Decision tree thresholds from tb_top
T0 = 10; T1 = 1; T2 = 80; T3 = 120; T4 = 90; T5 = 120; T6 = 130

# SA-ADC thresholds
M_T1=100; M_T2=180; L_T1=120; L_T2=200; H_T1=110; H_T2=210
AT_T1=115; AT_T2=220; LT_T1=130; LT_T2=230; BCRIT=50; BLOW=120

def ema_update(prev, sample, shift):
    prev_q8    = int(prev * 256)
    sample_q8  = int(sample * 256)
    delta      = sample_q8 - prev_q8
    new_q8     = prev_q8 + (delta >> shift)
    return new_q8 / 256

def compute_stress_score(sensors, weights, shift):
    total = sum(int(s) * int(w) for s, w in zip(sensors, weights))
    shifted = total >> shift
    return min(255, shifted)

def get_adc_mode(score, f_score, t1, t2, batt):
    if score < t1: base = 0
    elif score < t2: base = 1
    else: base = 2
    if f_score >= 2 and base == 1: base = 2
    if batt < BCRIT: return 0
    elif batt < BLOW: return min(1, base)
    return base

def analyze_trace(filename):
    path = os.path.join(TRACES_DIR, filename)
    if not os.path.exists(path):
        return None

    with open(path) as f:
        rows = list(csv.DictReader(f))

    if not rows:
        return None

    N = len(rows)
    battery = 200

    # EMA state (fast shift=2, slow shift=5 effectively)
    ema_fast = [None]*5; ema_slow = [None]*5
    prev_rel  = [False]*5; initialized = [False]*5
    cross_window = [0]*5; recent_dir = [False]*5

    total_warning = 0; total_critical = 0; total_monitor = 0
    total_stress_events = 0
    total_adc_bits = 0
    domain2_cycles = 0; domain3_cycles = 0
    n_stress_events = 0

    state = "MONITOR"  # start after chip_init

    for row in rows:
        sensors = [
            int(row['moisture']), int(row['leaf_temp']),
            int(row['humidity']), int(row['air_temp']),
            int(row['light'])
        ]

        # Update EMA fast (shift=2) and slow (shift=5)
        for i, s in enumerate(sensors):
            if ema_fast[i] is None:
                ema_fast[i] = s; ema_slow[i] = s
                initialized[i] = True
            else:
                ema_fast[i] = ema_update(ema_fast[i], s, 2)
                ema_slow[i]  = ema_update(ema_slow[i], s, 5)

        # Crossover detection
        fusion_score = 0
        for i in range(5):
            rel = ema_fast[i] > ema_slow[i]
            if initialized[i] and rel != prev_rel[i]:
                cross_window[i] = WINDOW_SIZE
                recent_dir[i] = rel
            elif cross_window[i] > 0:
                cross_window[i] -= 1
            prev_rel[i] = rel
            if cross_window[i] > 0:
                fusion_score += 1

        stress_event = (fusion_score >= VOTE_THRESHOLD)

        # Stress score
        score = compute_stress_score(sensors, W, SHIFT)

        # IPM FSM transitions
        if state == "MONITOR" and stress_event:
            state = "WARNING"
        elif state == "WARNING":
            sev = "CRITICAL" if score >= T0 and sensors[0] < T2 else "NORMAL"
            if score >= T0:
                state = "CRITICAL"
        elif state == "CRITICAL":
            if score < T0:
                state = "WARNING"

        # Dwell counters
        if state == "MONITOR":   total_monitor   += SAMPLES_PER_CYCLE
        elif state == "WARNING":  total_warning   += SAMPLES_PER_CYCLE; domain2_cycles += SAMPLES_PER_CYCLE
        elif state == "CRITICAL": total_critical  += SAMPLES_PER_CYCLE; domain2_cycles += SAMPLES_PER_CYCLE; domain3_cycles += SAMPLES_PER_CYCLE

        # ADC mode
        adc_modes = [
            get_adc_mode(score, fusion_score, M_T1,  M_T2,  battery),
            get_adc_mode(score, fusion_score, L_T1,   L_T2,  battery),
            get_adc_mode(score, fusion_score, H_T1,   H_T2,  battery),
            get_adc_mode(score, fusion_score, AT_T1,  AT_T2, battery),
            get_adc_mode(score, fusion_score, LT_T1,  LT_T2, battery),
        ]
        bits = [8, 10, 12]
        total_adc_bits += sum(bits[m] for m in adc_modes) / 5

        if stress_event:
            n_stress_events += 1

    # Duration based on sample count × cycles per sample × clock period
    total_sim_cycles = N * SAMPLES_PER_CYCLE
    duration_s   = total_sim_cycles / CLOCK_HZ
    # Scale to 1 hour: events per hour = events * (3600 / duration_s)
    events_per_hr = (n_stress_events / duration_s) * 3600 if duration_s > 0 else 0

    total_cycles = (total_monitor + total_warning + total_critical)

    return {
        "trace":            filename.replace(".csv",""),
        "samples":          N,
        "domain2_pct":      100.0 * domain2_cycles / total_cycles if total_cycles > 0 else 0,
        "domain3_pct":      100.0 * domain3_cycles / total_cycles if total_cycles > 0 else 0,
        "stress_events_hr": events_per_hr,
        "avg_adc_bits":     total_adc_bits / N if N > 0 else 0,
        "monitor_pct":      100.0 * total_monitor / total_cycles if total_cycles > 0 else 0,
        "warning_pct":      100.0 * total_warning / total_cycles if total_cycles > 0 else 0,
        "critical_pct":     100.0 * total_critical / total_cycles if total_cycles > 0 else 0,
    }


TRACES = [
    "baseline_diurnal.csv",
    "correlated_stress_01.csv",
    "correlated_stress_02.csv",
    "correlated_stress_03.csv",
]

print()
print("=" * 78)
print(" AgriSense-IPMS Activity Analysis — Table III Paper Data")
print("=" * 78)
print()
print(f" {'Trace':<28} | {'D2%':>6} | {'D3%':>6} | {'Evt/hr':>8} | {'Avg ADC':>8} | {'Monitor%':>9}")
print(f" {'-'*28}-+-{'-'*6}-+-{'-'*6}-+-{'-'*8}-+-{'-'*8}-+-{'-'*9}")

results = []
for t in TRACES:
    r = analyze_trace(t)
    if r:
        results.append(r)
        print(f" {r['trace']:<28} | {r['domain2_pct']:>5.1f}% | {r['domain3_pct']:>5.1f}% | "
              f"{r['stress_events_hr']:>8.1f} | {r['avg_adc_bits']:>7.1f}b | {r['monitor_pct']:>8.1f}%")

print()
print("=" * 78)
print(" Power-Saving Comparison Table (Table III Extension)")
print("=" * 78)
print()
print(f" {'Metric':<28} | {'Baseline':>10} | {'AgriSense':>10} | {'Reduction':>10}")
print(f" {'-'*28}-+-{'-'*10}-+-{'-'*10}-+-{'-'*10}")

if results:
    avg_d2 = sum(r['domain2_pct'] for r in results) / len(results)
    avg_d3 = sum(r['domain3_pct'] for r in results) / len(results)
    avg_adc = sum(r['avg_adc_bits'] for r in results) / len(results)
    adc_reduction = (12 - avg_adc) / 12 * 100

    print(f" {'CSA Active (Domain 2)':<28} | {'100.0%':>10} | {avg_d2:>9.1f}% | {100-avg_d2:>9.1f}%")
    print(f" {'DTree Active (Domain 2)':<28} | {'100.0%':>10} | {avg_d2:>9.1f}% | {100-avg_d2:>9.1f}%")
    print(f" {'LoRa Active (Domain 3)':<28} | {'100.0%':>10} | {avg_d3:>9.1f}% | {100-avg_d3:>9.1f}%")
    print(f" {'Avg ADC Resolution':<28} | {'12-bit':>10} | {avg_adc:>8.1f}b | {adc_reduction:>9.1f}%")
    # Energy savings approximation: D2 at 60% of total, D3 at 30%, base at 10%
    energy_ratio = 0.10 + 0.60*(avg_d2/100) + 0.30*(avg_d3/100)
    print(f" {'Relative Energy':<28} | {'1.00x':>10} | {energy_ratio:>9.2f}x | {(1-energy_ratio)*100:>9.1f}%")

print()
print("Note: Domain activity computed from Python EMA simulation model.")
print("      Final numbers will be confirmed from OpenROAD VCD power analysis.")
print()
