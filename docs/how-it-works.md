# Mechanism behind F5

## Chain

`F5` → `launch.json` profile → `preLaunchTask` (`tasks.json`) → `dotnet build` → Rhino.exe starts as the debuggee with `RHINO_PACKAGE_DIRS` set → Rhino loads every `.gha` in that folder → Grasshopper opens (`/runscript="_Grasshopper"`).

`RHINO_PACKAGE_DIRS` is the single mechanism that replaces the manual copy of the `.gha` into the Grasshopper Libraries folder.

## Files and roles

| File | Role |
|---|---|
| `<Name>/<Name>.csproj` | `TargetExt` `.gha`; `TargetFrameworks` `net7.0;net48`; `Grasshopper` package as a compile-time reference (`ExcludeAssets="runtime"`, so the output holds no Rhino DLLs) |
| `.vscode/launch.json` | Two profiles: `coreclr` debugger for the `net7.0` output (Rhino `/netcore`), `clr` debugger for the `net48` output (Rhino `/netfx`) |
| `.vscode/tasks.json` | `build (before launch)`: check that Rhino is closed, then build |
| `tools/launch-rhino.ps1` | The same sequence without the debugger; the check that Rhino is closed |
| `.vscode/settings.json` | Default solution, so the Problems panel covers the whole solution |
| `<Name>/Properties/launchSettings.json` | Start profiles for Visual Studio; VS Code does not read it |
| `Directory.Build.props` | C# language version `latest` for both targets (`net48` defaults to C# 7.3) |

## Components of the environment

| Component | Provides |
|---|---|
| .NET SDK | `dotnet build` for both targets; reference assemblies for `net48` are downloaded from NuGet |
| C# extension | The `coreclr` and `clr` debuggers |
| C# Dev Kit | Editor diagnostics, solution explorer |
| Rhino 8 | The host; provides Grasshopper, RhinoCommon, Newtonsoft.Json and System.Drawing at run time |

## Limits

| Limit | Reason |
|---|---|
| Rhino must be closed before a build | Rhino keeps the loaded `.gha` open, so the build cannot replace it. The scripts stop with `GH601` and never close Rhino |
| `RHINO_PACKAGE_DIRS` points at one target folder | The parent `bin/Debug` holds both targets; Rhino would load both and register each component twice |
| Windows only | The sample uses `System.Drawing`; the `net7.0` assembly is marked `SupportedOSPlatform("windows")` |
| Rhino path appears in five places | Two profiles in `launch.json`, two in `launchSettings.json`, one default in `launch-rhino.ps1`. `setup.ps1` rewrites all five |
| `ComponentGuid` and `GH_AssemblyInfo.Id` | Saved `.gh` files reference them. Changing either after release makes old definitions lose the component |
