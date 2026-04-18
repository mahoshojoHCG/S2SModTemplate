# S2SModTemplate

A `dotnet new` template for building [Slay the Spire 2](https://store.steampowered.com/app/2868840/Slay_the_Spire_2/) mods in C# with [Harmony](https://github.com/pardeike/Harmony).

## Quick Start

Install from NuGet:

```bash
dotnet new install S2SModTemplate.Templates
```

Or from a local checkout:

```bash
dotnet new install .
```

Scaffold a mod:

```bash
dotnet new sts2mod -n MyMod -o MyMod
cd MyMod
dotnet build
```

## Template Parameters

| Field          | Value                                                |
|----------------|------------------------------------------------------|
| Short name     | `sts2mod`                                            |
| Language       | C#                                                   |
| Target         | `net9.0`                                             |

| Option            | Default              | Purpose                                           |
|-------------------|----------------------|---------------------------------------------------|
| `-n`              | `MySts2Mod`          | Project name; drives assembly + manifest names    |
| `--RootNamespace` | `<name>`             | Root C# namespace                                 |
| `--HarmonyId`    | `sts2.<name>`        | Harmony instance id                               |
| `--ModName`       | `<name>`             | Display name written into the mod manifest       |
| `--Author`        | `YourName`           | Manifest author                                   |
| `--Description`   | `Slay the Spire 2 mod.` | Manifest description                          |
| `--ModVersion`    | `0.1.0`              | Manifest version                                  |

## What You Get

- `net9.0` mod project named after `-n`
- Steam-install path resolution (Windows / Linux / macOS arm64+x64)
- Reference-only links to `sts2.dll`, `0Harmony.dll`, `GodotSharp.dll`, `Steamworks.NET.dll` (not copied to output)
- `Bootstrap/ModEntry.cs` — `[ModInitializer]` entry point that runs `Harmony.PatchAll` and preloads `libgcc_s` / `libunwind` on Linux to keep transpiler patches working
- `Patching/ExamplePatches.cs` — empty stub showing the expected `[HarmonyPatch]` shape
- `<name>.json` — mod manifest with the values you passed in
- `install_skills.sh` — one-shot bootstrap for the optional ILSpy skill (see below)

## Game DLL Resolution

The generated `.csproj` resolves game DLLs from the default Steam install:

- **Windows** — `Steam\steamapps\common\Slay the Spire 2\data_sts2_windows_x86_64`
- **Linux** — `~/.local/share/Steam/steamapps/common/Slay the Spire 2/data_sts2_linuxbsd_x86_64`
- **macOS** — `~/Library/Application Support/Steam/steamapps/common/Slay the Spire 2/SlayTheSpire2.app/Contents/Resources/data_sts2_macos_{arm64,x86_64}`

Override `SteamCommonDir` in the generated `.csproj` if your library lives elsewhere.

## Optional: ILSpy Reference Skill

Each generated project ships `install_skills.sh`, a self-contained bootstrap that writes a `sts2-ilspy-reference` skill into the project's local `.codex/skills/` and `.claude/skills/`. The skill wraps `ilspycmd` to decompile `sts2.dll` into a searchable C# tree you can `rg` while writing patches.

```bash
./install_skills.sh                # install both
./install_skills.sh --only codex   # codex|claude|both
```

The script embeds the skill payload inline — there is no `skills/` folder to keep around. Once it has run, the project owns its local copies under `.codex/` and `.claude/`; commit them and delete the script.

## Repo Layout

| Path                              | Purpose                                                        |
|-----------------------------------|----------------------------------------------------------------|
| `S2SModTemplate.Templates.csproj` | Pack project for `dotnet pack`                                 |
| `templates/csharp/`               | Template payload + `.template.config/template.json`            |
| `templates/csharp/install_skills.sh` | Bootstrap that emits the local Codex/Claude skill files     |

`S2SModTemplate` is the placeholder source name. `template.json` rewrites it across file names, the assembly name, and the manifest path.

## Packing

```bash
dotnet pack S2SModTemplate.Templates.csproj
# → bin/Release/S2SModTemplate.Templates.0.1.0.nupkg
```
