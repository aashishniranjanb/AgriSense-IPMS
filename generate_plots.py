import sys
import os
import matplotlib.pyplot as plt
import numpy as np

# Simple VCD Parser in Python
class VCDParser:
    def __init__(self, filepath):
        self.filepath = filepath
        self.symbols = {} # symbol_char -> var_name
        self.data = {} # var_name -> list of (time_ns, value)
        self.parse()

    def parse(self):
        if not os.path.exists(self.filepath):
            print(f"Error: {self.filepath} does not exist.")
            return

        with open(self.filepath, 'r') as f:
            lines = f.readlines()

        current_time = 0.0 # in ns
        time_scale_factor = 1.0 # to ns (assuming 1ps or 1ns)
        
        in_header = True

        for line in lines:
            line = line.strip()
            if not line:
                continue

            # Header parsing
            if in_header:
                if line.startswith('$timescale'):
                    # e.g., $timescale 1ps $end or $timescale 1ns $end
                    parts = line.split()
                    if len(parts) >= 2:
                        ts = parts[1]
                        if 'ps' in ts:
                            time_scale_factor = 0.001 # ps to ns
                        elif 'ns' in ts:
                            time_scale_factor = 1.0
                elif line.startswith('$var'):
                    # e.g., $var wire 1 # clk $end
                    # or $var reg 8 ! moisture [7:0] $end
                    parts = line.split()
                    if len(parts) >= 5:
                        type_ = parts[1]
                        size = parts[2]
                        symbol = parts[3]
                        name = parts[4]
                        # remove [7:0] or similar if present
                        name = name.split('[')[0]
                        self.symbols[symbol] = name
                        if name not in self.data:
                            self.data[name] = []
                elif line.startswith('$enddefinitions'):
                    in_header = False
                continue

            # Value change parsing
            if line.startswith('#'):
                # Time marker, e.g. #100 or #50000 (in timescale units)
                try:
                    raw_time = int(line[1:])
                    current_time = raw_time * time_scale_factor
                except ValueError:
                    pass
            elif line.startswith('b'):
                # Vector value change, e.g., b10100100 # or b101 !
                parts = line.split()
                if len(parts) == 2:
                    val_str = parts[0][1:] # strip 'b'
                    symbol = parts[1]
                    if symbol in self.symbols:
                        name = self.symbols[symbol]
                        # Parse binary string
                        try:
                            val = int(val_str, 2)
                        except ValueError:
                            val = 0 # handle x or z as 0
                        self.data[name].append((current_time, val))
            elif line[0] in ('0', '1', 'x', 'z', 'X', 'Z') and len(line) >= 2:
                # Single bit change, e.g. 1# or 0!
                val_char = line[0]
                symbol = line[1:]
                if symbol in self.symbols:
                    name = self.symbols[symbol]
                    val = 1 if val_char == '1' else 0
                    self.data[name].append((current_time, val))

        # Fill in initial values at t=0 if missing
        for name in self.data:
            if not self.data[name] or self.data[name][0][0] > 0:
                self.data[name].insert(0, (0.0, 0))

    def get_signal_waveform(self, var_name, max_time_ns):
        if var_name not in self.data:
            print(f"Warning: Signal '{var_name}' not found in VCD data.")
            return np.array([0.0, max_time_ns]), np.array([0, 0])

        changes = self.data[var_name]
        times = []
        values = []

        for t, v in changes:
            if t > max_time_ns:
                break
            times.append(t)
            values.append(v)

        # Append final point to extend to max_time_ns
        if times[-1] < max_time_ns:
            times.append(max_time_ns)
            values.append(values[-1])

        return np.array(times), np.array(values)

def plot_gtkwave_style(parser, signals, title, output_path, max_time=1000):
    # Set dark theme like GTKWave
    plt.style.use('dark_background')
    
    fig, axes = plt.subplots(len(signals), 1, figsize=(12, 1.2 * len(signals) + 1.0), sharex=True)
    if len(signals) == 1:
        axes = [axes]

    fig.suptitle(title, fontsize=14, color='#00FF00', fontweight='bold', y=0.98)
    
    for idx, (sig_name, display_name, sig_type) in enumerate(signals):
        ax = axes[idx]
        times, values = parser.get_signal_waveform(sig_name, max_time)
        
        # Plot step function
        if sig_type == 'binary':
            # Binary signal (0 or 1)
            ax.step(times, values, where='post', color='#00FF00', linewidth=2.0)
            ax.fill_between(times, values, step='post', color='#00FF00', alpha=0.15)
            ax.set_ylim(-0.1, 1.1)
            ax.set_yticks([0, 1])
            ax.set_yticklabels(['0', '1'], fontsize=9, color='#FFFFFF')
        else:
            # Multi-bit bus (integer values)
            # Draw bus-style stepping
            ax.step(times, values, where='post', color='#00FFFF', linewidth=2.0)
            ax.fill_between(times, values, step='post', color='#00FFFF', alpha=0.08)
            
            # Print value labels inside the steps if they are long enough
            unique_times = list(times)
            unique_vals = list(values)
            for i in range(len(unique_times) - 1):
                t_start = unique_times[i]
                t_end = unique_times[i+1]
                val = unique_vals[i]
                if t_end - t_start > 30: # Only draw if step is wide enough
                    t_mid = (t_start + t_end) / 2
                    ax.text(t_mid, val, str(val), color='#FFFFFF', fontsize=8,
                            horizontalalignment='center', verticalalignment='center',
                            bbox=dict(facecolor='#000000', alpha=0.6, boxstyle='round,pad=0.2', edgecolor='none'))
            
            # Set y-limits with some margin
            v_min, v_max = min(values), max(values)
            if v_min == v_max:
                ax.set_ylim(v_min - 5, v_max + 5)
            else:
                ax.set_ylim(v_min - (v_max-v_min)*0.1 - 2, v_max + (v_max-v_min)*0.1 + 2)
            
            ax.tick_params(axis='y', colors='#FFFFFF', labelsize=9)

        # Style each axis
        ax.set_ylabel(display_name, rotation=0, labelpad=15, x=-0.05, ha='right', va='center',
                      color='#FFFF00', fontsize=10, fontweight='bold')
        ax.grid(True, which='both', color='#444444', linestyle=':', linewidth=0.5)
        ax.tick_params(axis='x', colors='#888888', labelsize=9)
        
        # Hide top and right spines
        ax.spines['top'].set_visible(False)
        ax.spines['right'].set_visible(False)
        ax.spines['left'].set_color('#888888')
        ax.spines['bottom'].set_color('#888888')

    # X-axis label on bottom axis
    axes[-1].set_xlabel('Time (ns)', color='#888888', fontsize=10, labelpad=5)
    
    # Adjust layout
    plt.tight_layout(rect=[0, 0, 1, 0.95])
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    plt.close()
    print(f"Successfully saved plot to {output_path}")

def main():
    print("Parsing VCD files...")
    
    # Fig 3: Fusion Unit Waveform
    fusion_vcd = "fusion_waveform.vcd"
    if os.path.exists(fusion_vcd):
        parser_fusion = VCDParser(fusion_vcd)
        
        # Print available signals to log
        print("Available signals in fusion_waveform.vcd:")
        print(list(parser_fusion.data.keys()))
        
        # Map of signals we want to show
        # format: (vcd_var_name, display_label, type)
        fusion_signals = [
            ('moisture', 'Soil Moisture', 'bus'),
            ('leaf_temp', 'Temp', 'bus'),
            ('humidity', 'Humidity', 'bus'),
            ('cross_flag', 'Moisture Cross', 'binary'), # decde_0 crossover flag
            # Wait, since there are multiple cross_flag signals, the parser merges them or indexes them.
            # Let's check how the parser loaded them.
        ]
        
        # Let's adjust to match parsed names
        # Since uut.u_decde_0.cross_flag, etc. might be parsed as cross_flag if the name splits
        # Let's use the exact names from parser_fusion.data
        matched_signals = []
        for name in ['moisture', 'leaf_temp', 'humidity']:
            if name in parser_fusion.data:
                matched_signals.append((name, name.upper(), 'bus'))
                
        # Find cross_flags
        cross_names = [k for k in parser_fusion.data.keys() if 'cross_flag' in k or 'cross' in k]
        for cn in sorted(cross_names)[:3]:
            matched_signals.append((cn, cn.split('.')[-2] + '_cross' if '.' in cn else cn, 'binary'))
            
        if 'fusion_score' in parser_fusion.data:
            matched_signals.append(('fusion_score', 'FUSION_SCORE', 'bus'))
        elif 'u_fusion.fusion_score' in parser_fusion.data:
            matched_signals.append(('u_fusion.fusion_score', 'FUSION_SCORE', 'bus'))
        else:
            # find anything with fusion_score
            fs_keys = [k for k in parser_fusion.data.keys() if 'fusion_score' in k]
            if fs_keys:
                matched_signals.append((fs_keys[0], 'FUSION_SCORE', 'bus'))
                
        if 'stress_event' in parser_fusion.data:
            matched_signals.append(('stress_event', 'FUSION_ALERT', 'binary'))
            
        print("Plotting Fusion Waveform with signals:", matched_signals)
        plot_gtkwave_style(parser_fusion, matched_signals, 
                            "AgriSense-IPMS Fig. 3: Fusion Unit Crossover Waveform", 
                            "figs/fusion_waveform.png", max_time=1200)

    # Fig 4: ADC Mode Transition
    adc_vcd = "adc_mode_transition.vcd"
    if os.path.exists(adc_vcd):
        parser_adc = VCDParser(adc_vcd)
        print("Available signals in adc_mode_transition.vcd:")
        print(list(parser_adc.data.keys()))
        
        adc_signals = []
        if 'battery' in parser_adc.data:
            adc_signals.append(('battery', 'BATTERY_LEVEL', 'bus'))
        if 'moisture' in parser_adc.data:
            adc_signals.append(('moisture', 'SENSOR_VARIANCE', 'bus'))
        if 'stress_score_iso' in parser_adc.data:
            adc_signals.append(('stress_score_iso', 'STRESS_SCORE', 'bus'))
            
        # find mode_moisture
        mm_keys = [k for k in parser_adc.data.keys() if 'mode_moisture' in k]
        if mm_keys:
            adc_signals.append((mm_keys[0], 'ADC_MODE', 'bus'))
            
        if 'adc_mode_vector' in parser_adc.data:
            adc_signals.append(('adc_mode_vector', 'ADC_MODE_VEC', 'bus'))
            
        print("Plotting ADC Waveform with signals:", adc_signals)
        plot_gtkwave_style(parser_adc, adc_signals, 
                            "AgriSense-IPMS Fig. 4: Adaptive ADC Resolution Transitions", 
                            "figs/adc_mode_transition.png", max_time=1100)

if __name__ == '__main__':
    main()
