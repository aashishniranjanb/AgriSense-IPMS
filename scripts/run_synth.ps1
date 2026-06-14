# run_synth.ps1 — Full Yosys block + top synthesis for Windows
# Runs Yosys block synthesis for all blocks and generates Table II data

$ErrorActionPreference = "Stop"

# Set up paths
$ProjRoot = Get-Location
$ReportDir = Join-Path $ProjRoot "synth/reports"
if (!(Test-Path $ReportDir)) {
    New-Item -ItemType Directory -Path $ReportDir | Out-Null
}

# Add OSS CAD Suite to path and set variables
$env:PATH = "C:\oss-cad-suite\bin;C:\oss-cad-suite\lib;" + $env:PATH
$env:VERILATOR_ROOT = "C:\oss-cad-suite\share\verilator"
$env:YOSYS_SHARE = "C:\oss-cad-suite\share\yosys"

$RtlFiles = @(
    "rtl/common/isolation_cell.v",
    "rtl/common/reg_bus_interconnect.v",
    "rtl/common/register_file.v",
    "rtl/common/synchronizer.v",
    "rtl/decde/ema_filter.v",
    "rtl/decde/crossover_detector.v",
    "rtl/decde/decde_channel.v",
    "rtl/decde/fusion_unit.v",
    "rtl/csa/weighted_sum.v",
    "rtl/csa/normalization_unit.v",
    "rtl/csa/crop_stress_accelerator.v",
    "rtl/dt/decision_tree_accelerator.v",
    "rtl/ipm/ipm_fsm.v",
    "rtl/ipm/power_controller.v",
    "rtl/ipm/wake_controller.v",
    "rtl/sa_adc/sa_adc_controller.v",
    "rtl/top/agrisense_ipms_top.v"
)

$IncludeDir = "rtl/common"

# Helper function to run synthesis on a block
function SynthBlock($TopModule) {
    $ReportFile = Join-Path $ReportDir "$($TopModule)_synth.rpt"
    Write-Host "`n--- Synthesizing: $TopModule ---"
    
    $FileListStr = $RtlFiles -join " "
    $YosysCmd = "read_verilog -I $IncludeDir $FileListStr; hierarchy -check -top $TopModule; proc; opt; techmap; opt; stat -top $TopModule"
    
    # Run yosys and redirect output
    & yosys.exe -p "$YosysCmd" > $ReportFile 2>&1
    
    Write-Host "    Report: $ReportFile"
}

# Step 1: Verilator Lint (zero warnings required)
Write-Host "========================================"
Write-Host " STEP 1: Verilator --lint-only -Wall"
Write-Host "========================================"
$FileListStr = $RtlFiles -join " "
$LintCmd = "verilator_bin.exe --lint-only -Wall --top-module agrisense_ipms_top +incdir+$IncludeDir $FileListStr"
Invoke-Expression $LintCmd
if ($LASTEXITCODE -ne 0) {
    Write-Host "VERILATOR: FAIL - fix warnings before synthesis"
    exit 1
}
Write-Host "VERILATOR: PASS"

# Step 2: Yosys Block Synthesis
Write-Host "`n========================================"
Write-Host " STEP 2: Yosys Block Synthesis"
Write-Host "========================================"
$Blocks = @(
    "sa_adc_controller",
    "fusion_unit",
    "crop_stress_accelerator",
    "decision_tree_accelerator",
    "ipm_fsm",
    "register_file"
)
foreach ($Block in $Blocks) {
    SynthBlock -TopModule $Block
}

# Step 3: Top-level synthesis
Write-Host "`n========================================"
Write-Host " STEP 3: Top-Level Synthesis"
Write-Host "========================================"
SynthBlock -TopModule "agrisense_ipms_top"

# Step 4: Summary Table (Table II data)
Write-Host "`n========================================"
Write-Host " SYNTHESIS SUMMARY - Table II Data"
Write-Host "========================================"
Write-Host " Block                     | Cells | Wires"
Write-Host "---------------------------|-------|------"
$AllModules = $Blocks + "agrisense_ipms_top"
foreach ($TopModule in $AllModules) {
    $ReportFile = Join-Path $ReportDir "$($TopModule)_synth.rpt"
    if (Test-Path $ReportFile) {
        $Content = Get-Content $ReportFile
        $Cells = "N/A"
        $Wires = "N/A"
        foreach ($Line in $Content) {
            if ($Line -match "^\s*(\d+)\s+cells") {
                $Cells = $Matches[1]
            }
            if ($Line -match "^\s*(\d+)\s+wires") {
                $Wires = $Matches[1]
            }
        }
        "{0,-26} | {1,-5} | {2}" -f $TopModule, $Cells, $Wires
    }
}
Write-Host "`nAll reports saved to: $ReportDir/"
