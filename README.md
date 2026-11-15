# RhinoGH-VSCode-Starter

A project template that brings the Visual Studio workflow for Rhino and Grasshopper plug-ins to VS Code. Pressing `F5` builds the plug-in, starts Rhino with Grasshopper open, loads the `.gha`, and attaches the debugger.

One project builds for Rhino 7, Rhino 8 and Rhino 9. Two ways to create it:

| Path | Performed by | Command or action |
|---|---|---|
| **1. Script** | The user | `setup.ps1 -Target <folder> -Name <PluginName>` |
| **2. Claude Code skill** | A Claude Code agent | Open this repository in Claude Code and ask for a project in a folder |

Both paths copy the same `template/` folder, so the resulting project is identical.

## Compatibility

| Rhino | Target framework | Rhino runtime | Compiled against |
|---|---|---|---|
| Rhino 7 | `net48` | .NET Framework 4.8 | `Grasshopper` 7.0.20314.3001 |
| Rhino 8.21 or later | `net8.0` | .NET 8 (default since Rhino 8.20) | `Grasshopper` 8.21.25188.17001 |
| Rhino 9 | `net10.0` | .NET 10 | `Grasshopper` 9.0.26300.9401 |

- Each target compiles against the first supported release of its Rhino version, so the output loads in every later service release of that version.
- A plug-in cannot target a newer .NET than the Rhino that loads it: Rhino 8 runs on .NET 8 and does not load a `net10.0` assembly. For this reason `net8.0` remains the Rhino 8 target although Microsoft support for .NET 8 has ended.
- All three targets build by default. Unused ones are removed in one line ([Selecting Rhino versions](#selecting-rhino-versions)).
- Windows only. Rhino for Mac, and VB or Python plug-ins, are out of scope.

## Requirements

| Requirement | Detail |
|---|---|
| Windows 10 or 11 | |
| Rhino | At least one of Rhino 7, Rhino 8.21 or later, Rhino 9, in the default location `C:\Program Files\Rhino <n>\System\Rhino.exe` or any other location (`-Rhino7Exe`, `-Rhino8Exe`, `-Rhino9Exe`) |
| VS Code | With the **C#** extension (`ms-dotnettools.csharp`), which provides the debugger. **C# Dev Kit** (`ms-dotnettools.csdevkit`) is recommended for editor diagnostics; its licence terms are Microsoft's. |
| .NET SDK 10 | Builds all three targets. The first build downloads NuGet packages (`Grasshopper`, reference assemblies) and requires internet access once. |
| Windows PowerShell 5.1 | Included with Windows. Runs `setup.ps1` and `tools/launch-rhino.ps1`. |
| Claude Code | Path 2 only |

These components are installed separately; this repository does not install them.

## Quick start

The **starter folder** (this repository, cloned or unzipped) and the **project folder** (the new plug-in) are separate. Only the contents of `template/` are copied into the project folder; the starter folder can be reused or deleted afterwards.

### Path 1: Script

1. Clone this repository, or download it as ZIP and extract it, into a location outside the new project folder.
2. In PowerShell, from the starter folder:

   ```powershell
   powershell -ExecutionPolicy Bypass -File .\setup.ps1 -Target D:\Dev\CoolTool -Name CoolTool
   ```

   | Parameter | Rule |
   |---|---|
   | `-Target` | New or empty folder. A non-empty folder is refused and nothing is written. |
   | `-Name` | Valid C# identifier (letters, digits, underscore; no leading digit). Becomes the namespace, project name, `.gha` file name and Grasshopper tab name. |
   | `-Rhino7Exe`, `-Rhino8Exe`, `-Rhino9Exe` | Optional. Required only for a Rhino installed outside the default location and the registry. `-RhinoExe` is accepted as an alias of `-Rhino8Exe`. |

3. Open the project folder in VS Code, close Rhino, press `F5`, and choose the profile of the installed Rhino version (`Rhino 8 (debug)`, `Rhino 9 (debug)` or `Rhino 7 (debug)`). Rhino starts with Grasshopper open; the tab named after the plug-in holds the sample component `Sum`.

Rhino 7 requires a one-time registration of the output folder through `GrasshopperDeveloperSettings`, because Rhino 7 does not read `RHINO_PACKAGE_DIRS`. The steps are in the `README.md` of the generated project.

### Path 2: Claude Code skill

The skill `rhino-gh-vscode-setup` is in `.claude/skills/` and loads when this repository is the working folder of Claude Code.

1. Open the starter folder in Claude Code.
2. Request a project, for example: *Set up a Grasshopper plug-in project named CoolTool in D:\Dev\CoolTool.*
3. The agent checks the requirements, runs `setup.ps1`, builds all targets, and reports the result. Missing requirements are reported, not installed.
4. Close Rhino, open the project folder in VS Code, and press `F5`.

## Selecting Rhino versions

All three targets build by default. To drop a Rhino version from a generated project:

1. Remove its target from `<TargetFrameworks>` in `<Name>/<Name>.csproj` (the matching `ItemGroup` can be removed as well).
2. Remove its profile from `.vscode/launch.json`, and from `<Name>/Properties/launchSettings.json` for Visual Studio.

Each `F5` profile builds only its own target, so unused targets do not slow down debugging; they only add time to a full build.

## Manual setup

Equivalent to `setup.ps1`. Copy the contents of `template/` (without `bin/` and `obj/`) into the project folder, then apply every row:

| Where | Find | Replace with |
|---|---|---|
| File and folder names (`MyPlugin.sln`, `MyPlugin/`, `MyPlugin.csproj`, `MyPluginInfo.cs`) | `MyPlugin` | Plug-in name |
| Text of every file | `MyPlugin` | Plug-in name |
| `MyPlugin/MyPluginInfo.cs` | `00000000-0000-4000-8000-0000000000a1` | New GUID (`[guid]::NewGuid()` in PowerShell) |
| `MyPlugin/Components/SumComponent.cs` | `00000000-0000-4000-8000-0000000000b1` | New GUID |
| `MyPlugin.sln` | `6E2F0B1C-4A3D-4C55-9B7E-1D2A3C4B5E01` (five places) | New GUID, upper case |
| `.vscode/launch.json`, `MyPlugin/Properties/launchSettings.json` | `C:\\Program Files\\Rhino <n>\\System\\Rhino.exe` (one per Rhino version in each file) | Full path of `Rhino.exe`, backslashes doubled |
| `tools/launch-rhino.ps1` (defaults of `-Rhino7Exe`, `-Rhino8Exe`, `-Rhino9Exe`) | `C:\Program Files\Rhino <n>\System\Rhino.exe` | Full path of `Rhino.exe` |

Rhino in the default location needs no path change. The template also builds with the name `MyPlugin` unchanged.

## Project layout

The generated project follows the Visual Studio default layout (solution folder, project folder, `Properties/`):

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

## Troubleshooting

| Symptom | Cause and fix |
|---|---|
| `error GH601: Rhino is running` | Rhino keeps the loaded `.gha` open, so a build cannot replace it. Close Rhino and press `F5` again. The scripts never close Rhino. |
| `error GH602: Rhino <n> executable not found` | Rhino is not in the default location. Rerun `setup.ps1` with `-Rhino<n>Exe`, or edit the path in `.vscode/launch.json` and `tools/launch-rhino.ps1`. |
| `F5` reports that `Rhino.exe` does not exist | The selected profile belongs to a Rhino version that is not installed. Choose another profile, or remove the version ([Selecting Rhino versions](#selecting-rhino-versions)). |
| `net10.0` fails with `NETSDK1045` | The installed .NET SDK is older than 10. Install .NET SDK 10, or remove the `net10.0` target. |
| The plug-in tab is missing in Rhino 7 | The `net48` output folder is not registered in `GrasshopperDeveloperSettings`. See the `README.md` of the generated project. |
| Each component appears twice | Grasshopper loads the plug-in from two folders: `RHINO_PACKAGE_DIRS` points at `bin/Debug` instead of one target folder, or a build folder registered in `GrasshopperDeveloperSettings` is read in addition to `RHINO_PACKAGE_DIRS`. Keep one source per Rhino session. |

## Repository contents

| Path | Content |
|---|---|
| `template/` | The project that is copied: solution, project, sample component, `.vscode/`, `tools/` |
| `setup.ps1` | Path 1 script: copy, rename, new GUIDs, Rhino paths |
| `.claude/skills/rhino-gh-vscode-setup/` | Path 2 skill |
| `docs/how-it-works.md` | The mechanism behind `F5`, and its limits |

## License

[MIT](LICENSE)
