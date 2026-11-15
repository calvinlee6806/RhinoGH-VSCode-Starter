# tools/launch-rhino.ps1
#
# Builds the plug-in for one Rhino version and starts that Rhino with Grasshopper open.
#
#   -Rhino 8   net8.0 target,  Rhino 8 (.NET 8)
#   -Rhino 9   net10.0 target, Rhino 9 (.NET 10)
#   -Rhino 7   net48 target,   Rhino 7 (.NET Framework 4.8)
#
# Rhino 8 and Rhino 9 load the build output through RHINO_PACKAGE_DIRS, so no copy step exists.
# Rhino 7 ignores RHINO_PACKAGE_DIRS; it loads the net48 output folder once that folder is added through the
# GrasshopperDeveloperSettings command.
#
# Rhino keeps the loaded .gha open, so a rebuild fails while Rhino runs. The script stops before building
# when a Rhino process exists and never closes Rhino itself (open documents stay safe).
#
# Usage:
#   launch-rhino.ps1                      Rhino 8, Debug
#   launch-rhino.ps1 -Rhino 9             Rhino 9
#   launch-rhino.ps1 -Rhino 7             Rhino 7
#   launch-rhino.ps1 -NoBuild             start Rhino with the existing build
#   launch-rhino.ps1 -CheckOnly           only check that no Rhino process is running
#   launch-rhino.ps1 -DryRun              build and check, print the launch command, do not start Rhino
#
# Exit codes: 0 success, 1 failure. Error lines use the MSBuild format for the VS Code problem matcher.

param(
  [ValidateSet('7', '8', '9')][string]$Rhino = '8',
  [string]$Configuration = 'Debug',
  [switch]$NoBuild,
  [switch]$CheckOnly,
  [switch]$DryRun,
  [string]$Rhino7Exe = 'C:\Program Files\Rhino 7\System\Rhino.exe',
  [string]$Rhino8Exe = 'C:\Program Files\Rhino 8\System\Rhino.exe',
  [string]$Rhino9Exe = 'C:\Program Files\Rhino 9\System\Rhino.exe'
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$project = Join-Path $repo 'MyPlugin\MyPlugin.csproj'

switch ($Rhino) {
  '7' { $tfm = 'net48';   $rhinoExe = $Rhino7Exe; $rhinoArgs = @('/runscript="_Grasshopper"') }
  '8' { $tfm = 'net8.0';  $rhinoExe = $Rhino8Exe; $rhinoArgs = @('/netcore', '/runscript="_Grasshopper"') }
  '9' { $tfm = 'net10.0'; $rhinoExe = $Rhino9Exe; $rhinoArgs = @('/netcore', '/runscript="_Grasshopper"') }
}
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

if (-not (Test-Path $rhinoExe)) { Fail 'GH602' "Rhino $Rhino executable not found at '$rhinoExe'. Pass -Rhino${Rhino}Exe, or change the default in this file." }

if (-not $NoBuild) {
  Write-Host "Building $tfm ($Configuration)..."
  & dotnet build $project -c $Configuration -f $tfm -clp:NoSummary
  if ($LASTEXITCODE -ne 0) { Fail 'GH603' 'Build failed; Rhino was not started.' }
}

$gha = Join-Path $outDir 'MyPlugin.gha'
if (-not (Test-Path $gha)) { Fail 'GH604' "Build output not found: $gha" }

$built = (Get-Item $gha).LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')
Write-Host "Starting Rhino $Rhino with $gha (built $built)"
$command = "$rhinoExe $($rhinoArgs -join ' ')"
if ($Rhino -eq '7') {
  Write-Host "Rhino 7 loads the plug-in from the folders listed in GrasshopperDeveloperSettings; $outDir must be one of them."
} else {
  $env:RHINO_PACKAGE_DIRS = $outDir
  $command = "RHINO_PACKAGE_DIRS=$outDir; $command"
}
if ($DryRun) { Write-Host "Dry run: $command"; exit 0 }
Start-Process -FilePath $rhinoExe -ArgumentList $rhinoArgs
