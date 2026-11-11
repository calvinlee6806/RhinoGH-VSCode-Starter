# setup.ps1
#
# Creates a Grasshopper plug-in project from the template/ folder of this repository.
#
# Actions:
#   1. Copies template/ into -Target (the folder must not exist, or must be empty).
#   2. Renames every file and folder named MyPlugin to -Name, and replaces the text MyPlugin in the copied files.
#   3. Replaces the placeholder GUIDs with new ones (assembly, component, project).
#   4. Writes the Rhino 8 executable path into .vscode/launch.json, Properties/launchSettings.json and
#      tools/launch-rhino.ps1 when it differs from the default (C:\Program Files\Rhino 8\System\Rhino.exe).
#
# Usage:
#   setup.ps1 -Target D:\Dev\MyTool -Name MyTool
#   setup.ps1 -Target D:\Dev\MyTool -Name MyTool -RhinoExe 'E:\Apps\Rhino 8\System\Rhino.exe'
#
# -Name must be a valid C# identifier (letters, digits, underscore; no leading digit). It becomes the namespace,
# the project name, the .gha file name and the Grasshopper tab name.
#
# Exit codes: 0 success, 1 failure. Nothing is written when a check fails.

param(
  [Parameter(Mandatory = $true)][string]$Target,
  [Parameter(Mandatory = $true)][string]$Name,
  [string]$RhinoExe = ''
)

$ErrorActionPreference = 'Stop'

function Fail([string]$message) {
  Write-Host "setup.ps1: error: $message"
  exit 1
}

$template = Join-Path $PSScriptRoot 'template'
if (-not (Test-Path $template)) { Fail "template folder not found at '$template'." }

if ($Name -notmatch '^[A-Za-z_][A-Za-z0-9_]*$') {
  Fail "-Name '$Name' is not a valid C# identifier (letters, digits, underscore; no leading digit)."
}

$target = [System.IO.Path]::GetFullPath($Target)
if (Test-Path $target) {
  if (-not (Test-Path $target -PathType Container)) { Fail "'$target' exists and is a file." }
  if (@(Get-ChildItem -Path $target -Force).Count -gt 0) { Fail "'$target' is not empty. Choose a new or empty folder; nothing was changed." }
}

# Rhino 8 executable: parameter, then the registry entry of the installer, then the default location.
$defaultRhino = 'C:\Program Files\Rhino 8\System\Rhino.exe'
if ($RhinoExe -eq '') {
  try {
    $install = Get-ItemProperty 'HKLM:\SOFTWARE\McNeel\Rhinoceros\8.0\Install' -ErrorAction Stop
    if ($install.ExePath) { $RhinoExe = $install.ExePath }
  } catch { }
}
if ($RhinoExe -eq '') { $RhinoExe = $defaultRhino }
if (-not (Test-Path $RhinoExe)) {
  Fail "Rhino 8 executable not found at '$RhinoExe'. Install Rhino 8, or pass -RhinoExe with the full path of Rhino.exe."
}

if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
  Write-Host 'setup.ps1: warning: dotnet was not found on PATH. Install the .NET SDK before building.'
}

# Copy.
New-Item -ItemType Directory -Path $target -Force | Out-Null
Copy-Item -Path (Join-Path $template '*') -Destination $target -Recurse -Force

# Rename files and folders, deepest first so that parent names are still valid.
Get-ChildItem -Path $target -Recurse -Force |
  Where-Object { $_.Name.Contains('MyPlugin') } |
  Sort-Object { $_.FullName.Length } -Descending |
  ForEach-Object { Rename-Item -LiteralPath $_.FullName -NewName $_.Name.Replace('MyPlugin', $Name) }

# Replace text.
$textExtensions = @('.cs', '.csproj', '.sln', '.json', '.ps1', '.md', '.props', '.gitignore')
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$guidAssembly = [guid]::NewGuid().ToString()
$guidComponent = [guid]::NewGuid().ToString()
$guidProject = [guid]::NewGuid().ToString().ToUpper()
$defaultRhinoJson = $defaultRhino.Replace('\', '\\')
$rhinoJson = $RhinoExe.Replace('\', '\\')

Get-ChildItem -Path $target -Recurse -Force -File |
  Where-Object { $textExtensions -contains $_.Extension.ToLower() } |
  ForEach-Object {
    $text = [System.IO.File]::ReadAllText($_.FullName)
    $new = $text.Replace('MyPlugin', $Name)
    $new = $new.Replace('00000000-0000-4000-8000-0000000000a1', $guidAssembly)
    $new = $new.Replace('00000000-0000-4000-8000-0000000000b1', $guidComponent)
    $new = $new.Replace('6E2F0B1C-4A3D-4C55-9B7E-1D2A3C4B5E01', $guidProject)
    if ($RhinoExe -ne $defaultRhino) {
      $new = $new.Replace($defaultRhinoJson, $rhinoJson)
      $new = $new.Replace($defaultRhino, $RhinoExe)
    }
    if ($new -ne $text) { [System.IO.File]::WriteAllText($_.FullName, $new, $utf8NoBom) }
  }

Write-Host "Created project '$Name' in $target"
Write-Host "Rhino: $RhinoExe"
Write-Host 'Next: open the folder in VS Code, close Rhino, press F5.'
