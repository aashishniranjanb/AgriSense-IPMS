"""
generate_traces.py
Generates synthetic agricultural sensor traces for AgriSense-IPMS simulation.
All sensor values are 8-bit unsigned integers (0-255).
Columns: cycle, moisture, leaf_temp, humidity, air_temp, light, battery
"""

import csv, os, math

OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "traces")
os.makedirs(OUT_DIR, exist_ok=True)

def write_csv(filename, header, rows):
    path = os.path.join(OUT_DIR, filename)
    with open(path, "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(header)
        w.writerows(rows)
    print(f"  Written: {path}  ({len(rows)} rows)")

HEADER = ["cycle","moisture","leaf_temp","humidity","air_temp","light","battery"]

# ============================================================
# 1. baseline_diurnal.csv  — Nominal conditions, no crossovers
# ============================================================
rows = []
for c in range(200):
    # Diurnal light sine wave. Moisture stable. No stress.
    moisture  = 140
    leaf_temp = 100 + int(10 * math.sin(2*math.pi*c/100))
    humidity  = 120
    air_temp  = 105 + int(8  * math.sin(2*math.pi*c/100))
    light     = 130 + int(20 * math.sin(2*math.pi*c/100))
    battery   = 200
    rows.append([c, moisture, leaf_temp, humidity, air_temp, light, battery])
write_csv("baseline_diurnal.csv", HEADER, rows)

# ============================================================
# 2. correlated_stress_01.csv  — Water Stress
#    Moisture falls steadily from 140 → 60.
#    Leaf temp rises from 100 → 145 (compensatory heating).
#    Other sensors stable.
# ============================================================
rows = []
for c in range(200):
    moisture  = max(60, 140 - c)          # drops 1/cycle → reaches 60 at cycle 80
    leaf_temp = min(145, 100 + c//2)      # rises 0.5/cycle
    humidity  = 120 - c//10              # slight decline
    air_temp  = 105
    light     = 120
    battery   = 200
    rows.append([c, moisture, leaf_temp, humidity, air_temp, light, battery])
write_csv("correlated_stress_01.csv", HEADER, rows)

# ============================================================
# 3. correlated_stress_02.csv  — Thermal Stress
#    Rapid temp spike (air + leaf). Moisture drops mildly.
# ============================================================
rows = []
for c in range(200):
    moisture  = max(100, 140 - c//3)
    leaf_temp = min(200, 100 + c)        # spikes fast
    humidity  = max(70, 120 - c//2)
    air_temp  = min(200, 100 + c)        # mirrors leaf_temp
    light     = 130
    battery   = 200
    rows.append([c, moisture, leaf_temp, humidity, air_temp, light, battery])
write_csv("correlated_stress_02.csv", HEADER, rows)

# ============================================================
# 4. correlated_stress_03.csv  — Multi-Factor, Temporally Staggered
#    Tests Fusion Unit sliding window: sensors cross at different cycles
#    moisture crosses at c=20, humidity at c=35, light spike at c=50
# ============================================================
rows = []
for c in range(200):
    # Moisture: steady decline starts at cycle 10
    moisture = 140 if c < 10 else max(50, 140 - (c-10)*2)
    # Humidity: starts declining at cycle 25
    humidity = 120 if c < 25 else max(60, 120 - (c-25)*2)
    # Light: spike at cycle 50 (stress due to over-illumination)
    light = 120 if c < 50 else min(220, 120 + (c-50)*2)
    # Leaf temp: mild rise
    leaf_temp = 100 + c//5
    air_temp  = 105
    battery   = 200
    rows.append([c, moisture, leaf_temp, humidity, air_temp, light, battery])
write_csv("correlated_stress_03.csv", HEADER, rows)

# ============================================================
# 5. heterogeneous_field.csv  — Noise / Threshold Margin Test
# ============================================================
import random
random.seed(42)
rows = []
for c in range(200):
    moisture  = 120 + random.randint(-20, 20)
    leaf_temp = 105 + random.randint(-15, 15)
    humidity  = 115 + random.randint(-20, 20)
    air_temp  = 108 + random.randint(-10, 10)
    light     = 125 + random.randint(-25, 25)
    battery   = 200
    rows.append([c, moisture, leaf_temp, humidity, air_temp, light, battery])
write_csv("heterogeneous_field.csv", HEADER, rows)

# ============================================================
# 6. homogeneous_field.csv  — All sensors identical flat baseline
# ============================================================
rows = []
for c in range(200):
    rows.append([c, 120, 100, 110, 105, 115, 200])
write_csv("homogeneous_field.csv", HEADER, rows)

print("Done. All 6 traces generated.")
