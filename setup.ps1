# setup.ps1
#
# Creates a Grasshopper plug-in project from the template/ folder of this repository.
#
# Actions:
#   1. Copies template/ into -Target (the folder must not exist, or must be empty).
#   2. Renames every file and folder named MyPlugin to -Name, and replaces the text MyPlugin in the copied files.
#   3. Replaces the placeholder GUIDs with new ones (assembly, component, project).
#   4. Writes the path of each installed Rhino version (7, 8, 9) into .vscode/launch.json,
#      Properties/launchSettings.json and tools/launch-rhino.ps1 when it differs from the default
#      (C:\Program Files\Rhino <n>\System\Rhino.exe).
#
# Usage:
#   setup.ps1 -Target D:\Dev\MyTool -Name MyTool
#   setup.ps1 -Target D:\Dev\MyTool -Name MyTool -Rhino8Exe 'E:\Apps\Rhino 8\System\Rhino.exe'
#
# -Name must be a valid C# identifier (letters, digits, underscore; no leading digit). It becomes the namespace,
# the project name, the .gha file name and the Grasshopper tab name.
#
# Each Rhino path is resolved from its parameter, then the registry entry of the installer, then the default
# location. At least one Rhino version must be found. A version that is not found keeps its default path.
# -RhinoExe is accepted as an alias of -Rhino8Exe.
#
# Exit codes: 0 success, 1 failure. Nothing is written when a check fails.

param(
  [Parameter(Mandatory = $true)][string]$Target,
  [Parameter(Mandatory = $true)][string]$Name,
  [string]$Rhino7Exe = '',
  [Alias('RhinoExe')][string]$Rhino8Exe = '',
  [string]$Rhino9Exe = ''
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

# Rhino executables, one per version: parameter, then registry, then default location.
# A candidate counts only when its file version has the expected major version: a newer Rhino installer can
# leave the registry entry of an older version pointing at the newer Rhino.exe.
function Test-RhinoExe([string]$path, [string]$version) {
  if ($path -eq '' -or -not (Test-Path $path -PathType Leaf)) { return $false }
  return [string](Get-Item $path).VersionInfo.FileMajorPart -eq $version
}

$requested = @{ '7' = $Rhino7Exe; '8' = $Rhino8Exe; '9' = $Rhino9Exe }
$rhinos = @()
foreach ($version in '7', '8', '9') {
  $default = "C:\Program Files\Rhino $version\System\Rhino.exe"
  $exe = $requested[$version]
  if ($exe -ne '') {
    if (-not (Test-RhinoExe $exe $version)) { Fail "'$exe' is not a Rhino $version executable (-Rhino${version}Exe)." }
  } else {
    $registryExe = ''
    try {
      $install = Get-ItemProperty "HKLM:\SOFTWARE\McNeel\Rhinoceros\$version.0\Install" -ErrorAction Stop
      if ($install.ExePath) { $registryExe = $install.ExePath }
    } catch { }
    if (Test-RhinoExe $registryExe $version) { $exe = $registryExe }
    elseif (Test-RhinoExe $default $version) { $exe = $default }
  }
  $found = $exe -ne ''
  if (-not $found) { $exe = $default }
  $rhinos += [pscustomobject]@{ Version = $version; Default = $default; Exe = $exe; Found = $found }
}
if (-not ($rhinos | Where-Object { $_.Found })) {
  Fail 'No Rhino 7, 8 or 9 executable found. Install Rhino, or pass -Rhino7Exe, -Rhino8Exe or -Rhino9Exe with the full path of Rhino.exe.'
}

if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
  Write-Host 'setup.ps1: warning: dotnet was not found on PATH. Install the .NET SDK 10 before building.'
}

# Copy, without build output (bin/, obj/) left by a build of template/ in place.
New-Item -ItemType Directory -Path $target -Force | Out-Null
$templateRoot = (Get-Item $template).FullName.TrimEnd('\')
Get-ChildItem -Path $templateRoot -Recurse -Force -File |
  Where-Object { $_.FullName.Substring($templateRoot.Length) -notmatch '\\(bin|obj)\\' } |
  ForEach-Object {
    $destination = Join-Path $target $_.FullName.Substring($templateRoot.Length + 1)
    New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force | Out-Null
    Copy-Item -LiteralPath $_.FullName -Destination $destination -Force
  }

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
$pathChanges = @($rhinos | Where-Object { $_.Found -and $_.Exe -ne $_.Default })

Get-ChildItem -Path $target -Recurse -Force -File |
  Where-Object { $textExtensions -contains $_.Extension.ToLower() } |
  ForEach-Object {
    $text = [System.IO.File]::ReadAllText($_.FullName)
    $new = $text.Replace('MyPlugin', $Name)
    $new = $new.Replace('00000000-0000-4000-8000-0000000000a1', $guidAssembly)
    $new = $new.Replace('00000000-0000-4000-8000-0000000000b1', $guidComponent)
    $new = $new.Replace('6E2F0B1C-4A3D-4C55-9B7E-1D2A3C4B5E01', $guidProject)
    foreach ($r in $pathChanges) {
      $new = $new.Replace($r.Default.Replace('\', '\\'), $r.Exe.Replace('\', '\\'))
      $new = $new.Replace($r.Default, $r.Exe)
    }
    if ($new -ne $text) { [System.IO.File]::WriteAllText($_.FullName, $new, $utf8NoBom) }
  }

Write-Host "Created project '$Name' in $target"
foreach ($r in $rhinos) {
  if ($r.Found) { Write-Host "Rhino $($r.Version): $($r.Exe)" }
  else { Write-Host "Rhino $($r.Version): not found; the 'Rhino $($r.Version) (debug)' profile keeps the default path." }
}
Write-Host 'Next: open the folder in VS Code, close Rhino, press F5.'
