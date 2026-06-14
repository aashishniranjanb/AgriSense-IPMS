# ==============================================================================
# SDC Timing Constraints - AgriSense-IPMS (90nm)
# Target Clock: 20 MHz (Clock Period = 50.0 ns)
# ==============================================================================

# Define clock
create_clock -name clk -period 50.0 [get_ports clk]

# Clock uncertainty and transition times
set_clock_uncertainty 0.5 [get_clocks clk]
set_clock_transition 0.2 [get_clocks clk]

# Input delays (assume 20% of clock period = 10.0 ns)
set_input_delay -clock clk 10.0 [remove_from_collection [all_inputs] [get_ports clk]]

# Output delays (assume 20% of clock period = 10.0 ns)
set_output_delay -clock clk 10.0 [all_outputs]

# Load and driving cell models
# Note: User should uncomment and update these names based on their target PDK cell definitions.
# set_driving_cell -lib_cell BUFX2 [all_inputs]
# set_load 0.05 [all_outputs]
