import sys
import os

if not os.path.exists("fusion_waveform.vcd"):
    print("VCD file not found")
    sys.exit(1)

with open("fusion_waveform.vcd", "r") as f:
    lines = f.readlines()

symbols = {}
data = {}

for line in lines:
    line = line.strip()
    if not line:
        continue
    if line.startswith("$var"):
        parts = line.split()
        if len(parts) >= 5:
            sym = parts[3]
            name = parts[4]
            name = name.split('[')[0]
            # store full path to distinguish signals
            full_path = " ".join(parts[4:-1])
            if not full_path:
                full_path = parts[4]
            symbols[sym] = full_path
            data[full_path] = []

current_time = 0
for line in lines:
    line = line.strip()
    if not line:
        continue
    if line.startswith("#"):
        try:
            current_time = int(line[1:])
        except ValueError:
            pass
    elif line.startswith("b"):
        parts = line.split()
        if len(parts) == 2:
            val_str = parts[0][1:]
            sym = parts[1]
            if sym in symbols:
                try:
                    val = int(val_str, 2)
                except ValueError:
                    val = 0
                data[symbols[sym]].append((current_time, val))
    elif len(line) >= 2 and line[0] in ('0', '1', 'x', 'z', 'X', 'Z'):
        val_char = line[0]
        sym = line[1:]
        if sym in symbols:
            val = 1 if val_char == '1' else 0
            data[symbols[sym]].append((current_time, val))

# Let's print out the changes of the key signals
print("=== VCD DEBUG PRINT ===")
for name in sorted(data.keys()):
    if any(k in name for k in ['moisture', 'leaf_temp', 'cross_flag', 'recent_cross', 'fusion_score', 'stress_event', 'window_ctr']):
        print(f"Signal: {name}")
        for t, v in data[name][:20]: # print first 20 changes
            print(f"  Time {t} ps: {v}")
