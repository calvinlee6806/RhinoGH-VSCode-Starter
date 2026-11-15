# Mechanism behind F5

## Chain

`F5` → `launch.json` profile → `preLaunchTask` (`tasks.json`): check that Rhino is closed, then `dotnet build -f <target>` → Rhino.exe starts as the debuggee → Grasshopper opens (`/runscript="_Grasshopper"`) and loads the `.gha`.

| Profile | Target | Debugger | Source of the `.gha` |
|---|---|---|---|
| `Rhino 8 (debug)` | `net8.0` | `coreclr` | `RHINO_PACKAGE_DIRS` = `<Name>/bin/Debug/net8.0` |
| `Rhino 9 (debug)` | `net10.0` | `coreclr` | `RHINO_PACKAGE_DIRS` = `<Name>/bin/Debug/net10.0` |
| `Rhino 7 (debug)` | `net48` | `clr` | Folder registered once through `GrasshopperDeveloperSettings` |

`RHINO_PACKAGE_DIRS` is the mechanism in Rhino 8 and Rhino 9 that replaces the manual copy of the `.gha` into the Grasshopper Libraries folder. Rhino 7 does not read it; the McNeel Rhino 7 templates rely on `GrasshopperDeveloperSettings` in the same way.

## Files and roles

| File | Role |
|---|---|
| `<Name>/<Name>.csproj` | `TargetExt` `.gha`; `TargetFrameworks` `net48;net8.0;net10.0`; one `Grasshopper` package version per target as a compile-time reference (`ExcludeAssets="runtime"`, so the output holds no Rhino DLLs) |
| `.vscode/launch.json` | One profile per Rhino version |
| `.vscode/tasks.json` | `build` (all targets, default build task); `build <target> (before launch)`: check that Rhino is closed, then build one target |
| `tools/launch-rhino.ps1` | The same sequence without the debugger (`-Rhino 7|8|9`); the check that Rhino is closed |
| `.vscode/settings.json` | Default solution, so the Problems panel covers the whole solution |
| `<Name>/Properties/launchSettings.json` | Start profiles for Visual Studio; VS Code does not read it |
| `<Name>/Properties/PlatformSupport.cs` | Marks the `net8.0` and `net10.0` assemblies as Windows-only |
| `Directory.Build.props` | C# language version `latest` for every target (`net48` defaults to C# 7.3) |

## Choice of target frameworks

| Rule | Consequence |
|---|---|
| A plug-in loads only in a runtime of the same or a newer .NET version | Rhino 8 (.NET 8) needs `net8.0`; a `net10.0` assembly fails to load there |
| Rhino 7 runs only on .NET Framework 4.8 | Rhino 7 needs `net48` |
| McNeel recommends `net10.0` for Rhino 9 | Rhino 9 uses `net10.0`. A `net8.0` assembly also loads in Rhino 9 through roll-forward, so a project that drops `net10.0` still runs there |
| Each target compiles against the first release of its Rhino version | Only APIs present in every service release are available, so one build covers the whole version |

Source: McNeel, [Moving to .NET Core](https://developer.rhino3d.com/en/guides/rhinocommon/moving-to-dotnet-core/).

## Components of the environment

| Component | Provides |
|---|---|
| .NET SDK 10 | `dotnet build` for all targets; reference assemblies for `net48` are downloaded from NuGet |
| C# extension | The `coreclr` and `clr` debuggers |
| C# Dev Kit | Editor diagnostics, solution explorer |
| Rhino | The host; provides Grasshopper, RhinoCommon, Newtonsoft.Json and System.Drawing at run time |

## Limits

| Limit | Reason |
|---|---|
| Rhino must be closed before a build | Rhino keeps the loaded `.gha` open, so the build cannot replace it. The scripts stop with `GH601` and never close Rhino |
| `RHINO_PACKAGE_DIRS` points at one target folder | The parent `bin/Debug` holds every target; Rhino would load all of them and register each component more than once |
| Rhino 7 needs a one-time setup | Rhino 7 ignores `RHINO_PACKAGE_DIRS`; the `net48` folder is registered through `GrasshopperDeveloperSettings` |
| Windows only | The sample uses `System.Drawing`; the `net8.0` and `net10.0` assemblies are marked `SupportedOSPlatform("windows")` |
| Each Rhino path appears in three places | One profile in `launch.json`, one in `launchSettings.json`, one default in `launch-rhino.ps1`. `setup.ps1` rewrites them for every Rhino version it finds |
| Registry entries of older Rhino versions can point at a newer Rhino | `setup.ps1` accepts a `Rhino.exe` only when its file version matches the expected major version |
| `ComponentGuid` and `GH_AssemblyInfo.Id` | Saved `.gh` files reference them. Changing either after release makes old definitions lose the component |
