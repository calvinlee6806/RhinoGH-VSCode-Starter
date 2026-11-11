# tools/launch-rhino.ps1
#
# Builds the plug-in for one runtime and starts Rhino 8 with Grasshopper open and the build output loaded.
# RHINO_PACKAGE_DIRS points at the output directory, so no copy step exists.
#
# Rhino keeps the loaded .gha open, so a rebuild fails while Rhino runs. The script stops before building
# when a Rhino process exists and never closes Rhino itself (open documents stay safe).
#
# Usage:
#   launch-rhino.ps1                      netcore (net7.0 target), Debug
#   launch-rhino.ps1 -Runtime netfx       .NET Framework (net48 target)
#   launch-rhino.ps1 -NoBuild             start Rhino with the existing build
#   launch-rhino.ps1 -CheckOnly           only check that no Rhino process is running
#   launch-rhino.ps1 -DryRun              build and check, print the launch command, do not start Rhino
#
# Exit codes: 0 success, 1 failure. Error lines use the MSBuild format for the VS Code problem matcher.

param(
  [ValidateSet('netcore', 'netfx')][string]$Runtime = 'netcore',
  [string]$Configuration = 'Debug',
  [switch]$NoBuild,
  [switch]$CheckOnly,
  [switch]$DryRun,
  [string]$RhinoExe = 'C:\Program Files\Rhino 8\System\Rhino.exe'
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$project = Join-Path $repo 'MyPlugin\MyPlugin.csproj'
$tfm = if ($Runtime -eq 'netcore') { 'net7.0' } else { 'net48' }
$outDir = Join-Path $repo "MyPlugin\bin\$Configuration\$tfm"

function Fail([string]$code, [string]$message) {
  Write-Host "launch-rhino.ps1(1): error ${code}: $message"
  exit 1
}

$running = @(Get-Process -Name Rhino -ErrorAction SilentlyContinue)
if ($running.Count -gt 0) {
  $ids = ($running | ForEach-Object { $_.Id }) -join ', '
  Fail 'GH601' "Rhino is running (PID $ids). Close it first: the loaded .gha is locked and the new build cannot replace it."
}
if ($CheckOnly) { Write-Host 'Rhino is not running.'; exit 0 }

if (-not (Test-Path $RhinoExe)) { Fail 'GH602' "Rhino executable not found at '$RhinoExe'. Pass -RhinoExe, or change the default in this file." }

if (-not $NoBuild) {
  Write-Host "Building $tfm ($Configuration)..."
  & dotnet build $project -c $Configuration -f $tfm -clp:NoSummary
  if ($LASTEXITCODE -ne 0) { Fail 'GH603' 'Build failed; Rhino was not started.' }
}

$gha = Join-Path $outDir 'MyPlugin.gha'
if (-not (Test-Path $gha)) { Fail 'GH604' "Build output not found: $gha" }

$built = (Get-Item $gha).LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')
Write-Host "Starting Rhino ($Runtime) with $gha (built $built)"
$env:RHINO_PACKAGE_DIRS = $outDir
if ($DryRun) { Write-Host "Dry run: RHINO_PACKAGE_DIRS=$outDir; $RhinoExe /$Runtime /runscript=`"_Grasshopper`""; exit 0 }
Start-Process -FilePath $RhinoExe -ArgumentList @("/$Runtime", '/runscript="_Grasshopper"')
