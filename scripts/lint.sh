#!/bin/bash
# Vivado xvlog compile/lint check script
E:/Xilinx/Vivado/2024.1/bin/xvlog.bat -i rtl/common \
  rtl/common/isolation_cell.v \
  rtl/common/reg_bus_interconnect.v \
  rtl/common/register_file.v \
  rtl/common/synchronizer.v \
  rtl/decde/ema_filter.v \
  rtl/decde/crossover_detector.v \
  rtl/decde/decde_channel.v \
  rtl/decde/fusion_unit.v \
  rtl/csa/weighted_sum.v \
  rtl/csa/crop_stress_accelerator.v \
  rtl/dt/decision_tree_accelerator.v \
  rtl/ipm/ipm_fsm.v \
  rtl/ipm/power_controller.v \
  rtl/ipm/wake_controller.v \
  rtl/sa_adc/sa_adc_controller.v \
  rtl/top/agrisense_ipms_top.v \
  tb/tb_top.v \
  tb/tb_sa_adc_controller.v
