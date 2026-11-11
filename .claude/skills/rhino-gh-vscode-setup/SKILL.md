---
name: rhino-gh-vscode-setup
description: Create a Grasshopper plug-in project that builds and debugs from VS Code with F5 (Rhino 8, Windows). Use when asked to set up, scaffold or initialise a Grasshopper (.gha) plug-in project, or to make VS Code behave like Visual Studio for Rhino and Grasshopper development, in a folder the user names.
---

# Set up a Rhino 8 / Grasshopper plug-in project for VS Code

Creates, in a folder chosen by the user, the Visual Studio default layout (solution, project folder, `Properties/`), a `.gha` project, the `.vscode/` files for `F5`, and `tools/launch-rhino.ps1`. The files come from `template/` of this repository through `setup.ps1`; the skill adds checks, a build, and a report.

Scope: Rhino 8 for Windows, C#. Rhino 7, Rhino for Mac, VB and Python plug-ins are out of scope; say so and stop.

## Inputs

| Input | Rule |
|---|---|
| Target folder | New or empty. Ask when not given. |
| Plug-in name | Valid C# identifier (letters, digits, underscore; no leading digit). It becomes the namespace, project, `.gha` and Grasshopper tab name. Ask when not given; propose one derived from the folder name. |
| Rhino path | Optional. Used only when Rhino 8 is not in the registry or the default location. |

## Steps

1. **Locate the starter repository.** `setup.ps1` and `template/` sit three levels above this skill folder (`<repo>/.claude/skills/rhino-gh-vscode-setup/`). When they are missing (skill copied elsewhere), ask for the clone location; do not recreate the template from memory.
2. **Check the target.** A non-empty existing folder stops the skill: report it and ask for another folder. Never delete or overwrite existing content.
3. **Check prerequisites** (report only; installing them is the user's responsibility, see the README):
   - `dotnet --list-sdks` shows SDK 8 or newer.
   - Rhino 8: registry `HKLM:\SOFTWARE\McNeel\Rhinoceros\8.0\Install` value `ExePath`, else `C:\Program Files\Rhino 8\System\Rhino.exe`.
   - `code --list-extensions` contains `ms-dotnettools.csharp`; `ms-dotnettools.csdevkit` is recommended.
   - Report every missing item in one message and wait for the user. Missing .NET SDK or Rhino blocks the build; a missing extension does not block project creation.
4. **Create the project.**

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File "<repo>\setup.ps1" -Target "<folder>" -Name "<Name>" [-RhinoExe "<path>"]
   ```

   Exit code 1 prints the reason; fix the input and rerun. `setup.ps1` writes nothing when a check fails.
5. **Build both targets.** `dotnet build "<folder>\<Name>.sln"`. Expected: 0 warnings, 0 errors, and `<Name>.gha` in `<folder>\<Name>\bin\Debug\net7.0\` and `...\net48\`. A failure is reported with its output; the generated files are left in place.
6. **Report.** One short message: folder, name, Rhino path used, build result, and the next action for the user: close Rhino, open the folder in VS Code, press `F5`, choose `Rhino 8 - netcore (debug)`. State that the `F5` run itself was not executed by the agent.

## Rules

- Never start, stop or close Rhino. A running Rhino only matters at `F5` time; mention it in the report.
- Never read, write or edit `.env` files.
- Run `setup.ps1` only against a new or empty folder.
- Keep `ComponentGuid` and `GH_AssemblyInfo.Id` values that `setup.ps1` generated; changing them after the first release breaks saved `.gh` files.
- Files written into the project (code, comments, commit messages) are in English.

## Manual fallback

When `setup.ps1` cannot run (PowerShell blocked), copy `template/` into the target and apply the find-and-replace table in the README (names, three GUIDs, five Rhino path occurrences).
