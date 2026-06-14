`ifndef AGRISENSE_DEFS_VH
`define AGRISENSE_DEFS_VH

// -----------------------------------------------------------------------------
// FSM States
// -----------------------------------------------------------------------------
`define IPM_SLEEP      2'b00
`define IPM_MONITOR    2'b01
`define IPM_WARNING    2'b10
`define IPM_CRITICAL   2'b11

// -----------------------------------------------------------------------------
// ADC Modes
// -----------------------------------------------------------------------------
`define ADC_8BIT       2'b00
`define ADC_10BIT      2'b01
`define ADC_12BIT      2'b10

// -----------------------------------------------------------------------------
// Sensor IDs
// -----------------------------------------------------------------------------
`define SENSOR_MOISTURE 3'd0
`define SENSOR_LEAFTEMP 3'd1
`define SENSOR_HUMIDITY 3'd2
`define SENSOR_AIRTEMP  3'd3
`define SENSOR_LIGHT    3'd4
`define SENSOR_BATTERY  3'd5

// -----------------------------------------------------------------------------
// Address Map
// -----------------------------------------------------------------------------

// SIE (0x00 - 0x0F)
`define REG_SENSOR_ENABLE    8'h00
`define REG_SENSOR_SELECT    8'h01
`define REG_SENSOR_STATUS    8'h02
`define REG_MOISTURE         8'h04
`define REG_LEAF_TEMP        8'h05
`define REG_HUMIDITY         8'h06
`define REG_AIR_TEMP         8'h07
`define REG_LIGHT            8'h08
`define REG_BATTERY          8'h09

// CSA (0x10 - 0x1F)
`define REG_W_MOISTURE       8'h10
`define REG_W_LEAFTEMP       8'h11
`define REG_W_HUMIDITY       8'h12
`define REG_W_AIRTEMP        8'h13
`define REG_W_LIGHT          8'h14
`define REG_STRESS_SCORE     8'h18
`define REG_CSA_SHIFT        8'h19
`define REG_WEIGHT_STATUS    8'h1A

// DECDE (0x20 - 0x4F)
// (Reserved for Phase 2: DECDE Channels)

// Fusion (0x50 - 0x5F)
`define REG_CROSS_FLAG_VEC   8'h50
`define REG_WINDOW_SIZE      8'h51
`define REG_VOTE_THRESHOLD   8'h52
`define REG_FUSION_SCORE     8'h53
`define REG_STRESS_EVENT     8'h54
`define REG_FUSION_PATTERN_LSB 8'h55
`define REG_FUSION_PATTERN_MSB 8'h56

// Decision Tree (0x60 - 0x7F)
`define REG_DT_T0            8'h60
`define REG_DT_T1            8'h61
`define REG_DT_T2            8'h62
`define REG_DT_T3            8'h63
`define REG_DT_T4            8'h64
`define REG_DT_T5            8'h65
`define REG_DT_T6            8'h66
`define REG_LEAF_OUTPUT      8'h70

// SA-ADC (0x80 - 0x9F)
`define REG_MOISTURE_T1      8'h80
`define REG_MOISTURE_T2      8'h81
`define REG_LEAF_T1          8'h82
`define REG_LEAF_T2          8'h83
`define REG_HUMIDITY_T1      8'h84
`define REG_HUMIDITY_T2      8'h85
`define REG_AIR_T1           8'h86
`define REG_AIR_T2           8'h87
`define REG_LIGHT_T1         8'h88
`define REG_LIGHT_T2         8'h89
`define REG_B_CRIT           8'h8A
`define REG_B_LOW            8'h8B
`define REG_ADC_MODE_LSB     8'h8C
`define REG_ADC_MODE_MSB     8'h8D

// IPM (0xA0 - 0xAF)
`define REG_IPM_STATE        8'hA0
`define REG_ENABLES          8'hA1
`define REG_BATTERY_LEVEL    8'hA2

`endif // AGRISENSE_DEFS_VH
