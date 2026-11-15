---
name: rhino-gh-vscode-setup
description: Create a Grasshopper plug-in project that builds and debugs from VS Code with F5 (Rhino 7, 8 and 9, Windows). Use when asked to set up, scaffold or initialise a Grasshopper (.gha) plug-in project, or to make VS Code behave like Visual Studio for Rhino and Grasshopper development, in a folder the user names.
---

# Set up a Rhino / Grasshopper plug-in project for VS Code

Creates, in a folder chosen by the user, the Visual Studio default layout (solution, project folder, `Properties/`), a `.gha` project with one target per Rhino version (`net48` Rhino 7, `net8.0` Rhino 8.21+, `net10.0` Rhino 9), the `.vscode/` files for `F5`, and `tools/launch-rhino.ps1`. The files come from `template/` of this repository through `setup.ps1`; the skill adds checks, a build, and a report.

Scope: Rhino 7, 8 and 9 for Windows, C#. Rhino for Mac, VB and Python plug-ins are out of scope; say so and stop.

## Inputs

| Input | Rule |
|---|---|
| Target folder | New or empty. Ask when not given. |
| Plug-in name | Valid C# identifier (letters, digits, underscore; no leading digit). It becomes the namespace, project, `.gha` and Grasshopper tab name. Ask when not given; propose one derived from the folder name. |
| Rhino paths | Optional (`-Rhino7Exe`, `-Rhino8Exe`, `-Rhino9Exe`). Used only when a Rhino version is not in the registry or the default location. |

## Steps

1. **Locate the starter repository.** `setup.ps1` and `template/` sit three levels above this skill folder (`<repo>/.claude/skills/rhino-gh-vscode-setup/`). When they are missing (skill copied elsewhere), ask for the clone location; do not recreate the template from memory.
2. **Check the target.** A non-empty existing folder stops the skill: report it and ask for another folder. Never delete or overwrite existing content.
3. **Check prerequisites** (report only; installing them is the user's responsibility, see the README):
   - `dotnet --list-sdks` shows SDK 10 or newer (required for the `net10.0` target).
   - At least one Rhino: `C:\Program Files\Rhino <n>\System\Rhino.exe` for 7, 8 or 9, or the registry value `HKLM:\SOFTWARE\McNeel\Rhinoceros\<n>.0\Install\ExePath`. The registry value of an older version can point at a newer Rhino; `setup.ps1` checks the file version.
   - Rhino 8 must be 8.21 or later (file version of `Rhino.exe`).
   - `code --list-extensions` contains `ms-dotnettools.csharp`; `ms-dotnettools.csdevkit` is recommended.
   - Report every missing item in one message and wait for the user. Missing .NET SDK or no Rhino blocks the build; a missing extension does not block project creation.
4. **Create the project.**

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File "<repo>\setup.ps1" -Target "<folder>" -Name "<Name>" [-Rhino8Exe "<path>"]
   ```

   Exit code 1 prints the reason; fix the input and rerun. `setup.ps1` writes nothing when a check fails. Its output lists the Rhino path used for each version, or "not found".
5. **Build all targets.** `dotnet build "<folder>\<Name>.sln"`. Expected: 0 warnings, 0 errors, and `<Name>.gha` in `<folder>\<Name>\bin\Debug\net48\`, `...\net8.0\` and `...\net10.0\`. A failure is reported with its output; the generated files are left in place.
6. **Report.** One short message: folder, name, Rhino versions found, build result, and the next action for the user: close Rhino, open the folder in VS Code, press `F5`, choose the profile of an installed Rhino version (`Rhino 8 (debug)`, `Rhino 9 (debug)`, `Rhino 7 (debug)`). For Rhino 7, point to the one-time `GrasshopperDeveloperSettings` step in the project `README.md`. When the user uses only some Rhino versions, mention that unused targets are removed as described in the README. The agent cannot press `F5` for the user.

## Rules

- Never start, stop or close Rhino. A running Rhino only matters at `F5` time; mention it in the report.
- Never read, write or edit `.env` files.
- Run `setup.ps1` only against a new or empty folder.
- Keep `ComponentGuid` and `GH_AssemblyInfo.Id` values that `setup.ps1` generated; changing them after the first release breaks saved `.gh` files.
- Files written into the project (code, comments, commit messages) are in English.

## Manual fallback

When `setup.ps1` cannot run (PowerShell blocked), copy `template/` (without `bin/` and `obj/`) into the target and apply the find-and-replace table in the README (names, three GUIDs, Rhino paths).
