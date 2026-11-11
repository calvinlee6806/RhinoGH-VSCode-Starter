# MyPlugin

Grasshopper plug-in for Rhino 8 (Windows). Built and debugged from VS Code.

## Run

1. Close Rhino.
2. Press `F5` and choose `Rhino 8 - netcore (debug)` (`Rhino 8 - netfx (debug)` for the .NET Framework runtime).
3. Rhino starts with Grasshopper open. The `MyPlugin` tab holds the sample component `Sum`.

Terminal alternative: `powershell -ExecutionPolicy Bypass -File tools/launch-rhino.ps1 [-Runtime netfx] [-NoBuild]`.

## Layout

| Path | Content |
|---|---|
| `MyPlugin.sln` | Solution (opens in Visual Studio and VS Code) |
| `MyPlugin/MyPlugin.csproj` | Project: targets `net7.0` and `net48`, output extension `.gha` |
| `MyPlugin/MyPluginInfo.cs` | Assembly identity in Grasshopper (`GH_AssemblyInfo`) |
| `MyPlugin/Components/` | Components, one file each |
| `MyPlugin/Properties/launchSettings.json` | Start profiles for Visual Studio |
| `.vscode/` | `F5` profiles (`launch.json`), build tasks (`tasks.json`), editor settings |
| `tools/launch-rhino.ps1` | Build and start Rhino without the debugger |

## Rules that keep saved definitions loadable

- `ComponentGuid` and `GH_AssemblyInfo.Id` stay unchanged after the first release.
- Every new component gets a new Guid (`[guid]::NewGuid()` in PowerShell).
- `RHINO_PACKAGE_DIRS` points at one target folder only (`net7.0` or `net48`). Pointing at `bin/Debug` loads both and registers every component twice.
