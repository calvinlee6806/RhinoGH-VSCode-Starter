# MyPlugin

Grasshopper plug-in for Rhino 7, Rhino 8 and Rhino 9 (Windows). Built and debugged from VS Code.

## Run

1. Close Rhino.
2. Press `F5` and choose the profile of the installed Rhino version:

   | Profile | Target | Rhino |
   |---|---|---|
   | `Rhino 8 (debug)` | `net8.0` | Rhino 8.21 or later |
   | `Rhino 9 (debug)` | `net10.0` | Rhino 9 |
   | `Rhino 7 (debug)` | `net48` | Rhino 7 (one-time setup below) |

3. Rhino starts with Grasshopper open. The `MyPlugin` tab holds the sample component `Sum`.

The profile builds only its own target. `Ctrl+Shift+B` builds all three.

Terminal alternative: `powershell -ExecutionPolicy Bypass -File tools/launch-rhino.ps1 [-Rhino 7|8|9] [-NoBuild]`.

### Rhino 7 one-time setup

Rhino 7 does not read `RHINO_PACKAGE_DIRS`, so Grasshopper needs the output folder registered once:

1. Build once (`Ctrl+Shift+B`), then start Rhino 7 and run the command `GrasshopperDeveloperSettings`.
2. Add the folder `MyPlugin\bin\Debug\net48` of this project.
3. Clear *Memory load \*.GHA assemblies using COFF byte arrays*, so the debugger can bind breakpoints.
4. Close Rhino 7. `F5` with `Rhino 7 (debug)` then loads the build from that folder.

## Layout

| Path | Content |
|---|---|
| `MyPlugin.sln` | Solution (opens in Visual Studio and VS Code) |
| `MyPlugin/MyPlugin.csproj` | Project: targets `net48`, `net8.0`, `net10.0`; output extension `.gha` |
| `MyPlugin/MyPluginInfo.cs` | Assembly identity in Grasshopper (`GH_AssemblyInfo`) |
| `MyPlugin/Components/` | Components, one file each |
| `MyPlugin/Properties/launchSettings.json` | Start profiles for Visual Studio |
| `.vscode/` | `F5` profiles (`launch.json`), build tasks (`tasks.json`), editor settings |
| `tools/launch-rhino.ps1` | Build and start Rhino without the debugger |
| `Directory.Build.props` | C# language version `latest` for every target (`net48` defaults to C# 7.3) |

## Removing a Rhino version

1. Remove its target from `<TargetFrameworks>` in `MyPlugin/MyPlugin.csproj`, and optionally the matching `ItemGroup`.
2. Remove its profile from `.vscode/launch.json` (and from `MyPlugin/Properties/launchSettings.json` for Visual Studio).

Code that uses an API of a newer Rhino version only is guarded with `#if NET8_0_OR_GREATER` (Rhino 8 and 9) or `#if NET10_0_OR_GREATER` (Rhino 9) while several targets remain.

## Rules that keep saved definitions loadable

- `ComponentGuid` and `GH_AssemblyInfo.Id` stay unchanged after the first release.
- Every new component gets a new Guid (`[guid]::NewGuid()` in PowerShell).
- `RHINO_PACKAGE_DIRS` points at one target folder only. Pointing at `bin/Debug` loads every target and registers each component more than once.
