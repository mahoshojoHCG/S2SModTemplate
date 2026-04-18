# S2SModTemplate

A C# template for building a [Slay the Spire 2](https://store.steampowered.com/app/2868840/Slay_the_Spire_2/) mod with [Harmony](https://github.com/pardeike/Harmony).

When you run `dotnet new sts2mod -n MyMod`, the template engine rewrites `S2SModTemplate` (project, assembly, manifest filename) and the placeholder tokens (`MOD_NAMESPACE`, `MOD_HARMONY_ID`, `MOD_DISPLAY_NAME`, `MOD_AUTHOR`, `MOD_DESCRIPTION`, `MOD_VERSION`) using the parameters you pass.

## Requirements

- .NET 9 SDK
- Slay the Spire 2 installed through Steam

The csproj references the game's managed DLLs directly from the default Steam location:

- Windows: `Steam\steamapps\common\Slay the Spire 2\data_sts2_windows_x86_64`
- Linux: `~/.local/share/Steam/steamapps/common/Slay the Spire 2/data_sts2_linuxbsd_x86_64`
- macOS: `~/Library/Application Support/Steam/steamapps/common/Slay the Spire 2/SlayTheSpire2.app/Contents/Resources/data_sts2_macos_{arm64,x86_64}`

If your Steam library is elsewhere, override `SteamCommonDir` in the generated `.csproj`.

## Project Layout

| File / Folder                  | Purpose                                                                 |
|--------------------------------|-------------------------------------------------------------------------|
| `S2SModTemplate.csproj`        | Target framework, Steam path resolution, DLL references, manifest copy  |
| `S2SModTemplate.json`          | Mod manifest (schema, name, author, description, version)              |
| `Bootstrap/ModEntry.cs`        | `[ModInitializer]` entry point — runs `Harmony.PatchAll`               |
| `Patching/ExamplePatches.cs`   | Empty stub showing the expected `[HarmonyPatch]` shape                 |
| `install_skills.sh`            | One-shot bootstrap for the optional ILSpy reference skill              |

`ModEntry.Initialize` also preloads `libgcc_s` / `libunwind` with `RTLD_GLOBAL` on Linux. Without that, Harmony's transpiler path can fail to resolve those libraries inside the Godot host.

## Build

```bash
dotnet build
```

`sts2.dll` and `0Harmony.dll` are reference-only (`<Private>false</Private>`) and are not copied into your output. The manifest (`<name>.json`) is copied next to the assembly.

## Optional: Codex / Claude ILSpy Skill

`install_skills.sh` writes a self-contained `sts2-ilspy-reference` skill into the project's local `.codex/skills/` and `.claude/skills/`. The skill wraps `ilspycmd` to decompile `sts2.dll` into a searchable C# tree.

```bash
./install_skills.sh                # install both
./install_skills.sh --only claude  # codex|claude|both
```

The script embeds the skill payload inline — there is no `skills/` folder to manage. After it runs, the project owns its local skills; commit them and delete the script.
