# RhinoGH-VSCode-Starter

A template package that brings the native Visual Studio development environment for Rhino and Grasshopper plug-ins into VS Code. Pressing `F5` in VS Code builds the current project, starts Rhino with Grasshopper open, loads the `.gha` file, and attaches the debugger.

Target: Rhino 8, Windows. Two ways to create the project:

| Path | Who does the work | Command or action |
|---|---|---|
| **1. Template** | The user, with `setup.ps1` or a find-and-replace table | `setup.ps1 -Target <folder> -Name <PluginName>` |
| **2. Skill** | A Claude Code agent | Open this repository in Claude Code and ask for a project in a folder |

Both paths copy the same `template/` folder, so the resulting project is identical.

## Prerequisites

Installed by the user before either path. This repository installs none of them and does not support their installation.

| Requirement | Detail |
|---|---|
| Windows 10 or 11 | Rhino 8 for Windows. macOS is not supported. |
| Rhino 8 | Default location `C:\Program Files\Rhino 8\System\Rhino.exe`. Another location is accepted (`-RhinoExe`). |
| VS Code | With the **C#** extension (`ms-dotnettools.csharp`), which provides the debugger used by `F5`. **C# Dev Kit** (`ms-dotnettools.csdevkit`) is recommended for editor diagnostics; its licence terms are Microsoft's. |
| .NET SDK 8 or newer | Builds both targets (`net7.0`, `net48`). Verified with 10.0.301. The first build downloads NuGet packages (`Grasshopper`, reference assemblies), so internet access is required once. |
| Windows PowerShell 5.1 | Included with Windows. Runs `setup.ps1` and `tools/launch-rhino.ps1`. |
| Claude Code (Path 2 only) | A running Claude Code with access to this repository. |

## Two separate folders

| Folder | Role | Content |
|---|---|---|
| **Project folder** (example `D:\Dev\CoolTool`) | The new plug-in project | Must be new or empty. Receives only the files of `template/`. |
| **Starter folder** (example `D:\Tools\RhinoGH-VSCode-Starter`) | This repository, cloned or unzipped | Holds `setup.ps1`, `template/` and the skill. Stays outside the project folder; it can be reused for further projects or deleted afterwards. |

`git clone` and *Download ZIP* both create a wrapper folder named after the repository; the wrapper folder is the starter folder. `README.md`, `LICENSE`, `docs/` and `.gitignore` of this repository are not copied into the project.

## Path 1: Template

1. **Create the project folder.** A new folder, or an empty one. `setup.ps1` refuses a non-empty folder.
2. **Get this repository into a different location.** `git clone` or *Code → Download ZIP* on GitHub (then unzip) into the starter folder, outside the project folder.
3. **Create the project.** In PowerShell, from the starter folder:

   ```powershell
   powershell -ExecutionPolicy Bypass -File .\setup.ps1 -Target D:\Dev\CoolTool -Name CoolTool
   ```

   `-Name` is the plug-in name: a valid C# identifier (letters, digits, underscore; no leading digit). It becomes the namespace, the project name, the `.gha` file name, and the Grasshopper tab name. Add `-RhinoExe '<full path>'` when Rhino 8 is not in the default location or the registry.
4. **Test.** Open the project folder in VS Code, close Rhino, press `F5`, choose `Rhino 8 - netcore (debug)`. Rhino starts with Grasshopper open; the tab named after the plug-in holds the sample component `Sum`.

### Manual alternative to `setup.ps1`

Copy the contents of `template/` into the project folder, then apply every row:

| Where | Find | Replace with |
|---|---|---|
| File and folder names (`MyPlugin.sln`, `MyPlugin/`, `MyPlugin.csproj`, `MyPluginInfo.cs`) | `MyPlugin` | Plug-in name |
| Text of every file | `MyPlugin` | Plug-in name |
| `MyPlugin/MyPluginInfo.cs` | `00000000-0000-4000-8000-0000000000a1` | New GUID (`[guid]::NewGuid()` in PowerShell) |
| `MyPlugin/Components/SumComponent.cs` | `00000000-0000-4000-8000-0000000000b1` | New GUID |
| `MyPlugin.sln` | `6E2F0B1C-4A3D-4C55-9B7E-1D2A3C4B5E01` (five places) | New GUID, upper case |
| `.vscode/launch.json` (2 places), `MyPlugin/Properties/launchSettings.json` (2 places) | `C:\\Program Files\\Rhino 8\\System\\Rhino.exe` | Full path of `Rhino.exe`, backslashes doubled |
| `tools/launch-rhino.ps1` (default of `-RhinoExe`) | `C:\Program Files\Rhino 8\System\Rhino.exe` | Full path of `Rhino.exe` |

Rhino in the default location needs no path change. The template builds with the name `MyPlugin` unchanged.

## Path 2: Skill

The skill `rhino-gh-vscode-setup` is in `.claude/skills/`. Claude Code loads it when this repository is the working folder.

1. Create the project folder (new or empty). Clone this repository into a different location (the starter folder) and open the **starter folder** in Claude Code.
2. Ask, for example: *Set up a Grasshopper plug-in project named CoolTool in D:\Dev\CoolTool.*
3. The agent checks the prerequisites, runs `setup.ps1`, builds both targets, and reports the result. It reports missing prerequisites and does not install them.
4. Close Rhino, open the project folder in VS Code, press `F5`. The agent cannot press `F5` for the user.

## Contents

| Path | Content |
|---|---|
| `template/` | The project that is copied: solution, project, sample component, `.vscode/`, `tools/` |
| `setup.ps1` | Path 1 script: copy, rename, new GUIDs, Rhino path |
| `.claude/skills/rhino-gh-vscode-setup/` | Path 2 skill |
| `docs/how-it-works.md` | The mechanism behind `F5`, and the limits |

Layout of the generated project (the Visual Studio default: solution folder, project folder, `Properties/`):

```text
<Target>/
├─ <Name>.sln
├─ Directory.Build.props
├─ .gitignore
├─ README.md
├─ .vscode/            extensions.json, settings.json, launch.json, tasks.json
├─ tools/              launch-rhino.ps1
└─ <Name>/
   ├─ <Name>.csproj
   ├─ <Name>Info.cs
   ├─ Components/      SumComponent.cs
   └─ Properties/      launchSettings.json, PlatformSupport.cs
```

## Scope and verification

| Item | State |
|---|---|
| Rhino 8 on Windows, C# | Supported |
| Rhino 7, Rhino for Mac, VB or Python plug-ins | Not supported |
| Both targets build with 0 warnings and 0 errors (SDK 10.0.301) | Verified on the template and on a project generated by `setup.ps1` |
| `setup.ps1`: valid name, new GUIDs, no `MyPlugin` left, Rhino path rewrite, refusal of invalid name, missing Rhino and non-empty folder | Verified |
| `tools/launch-rhino.ps1 -DryRun` for `netcore` and `netfx` | Verified |
| `F5` with the debugger attached, and loading the `.gha` in Rhino | The `.vscode/` files are taken from a project where this works; the generated project has not been run through `F5` itself |
