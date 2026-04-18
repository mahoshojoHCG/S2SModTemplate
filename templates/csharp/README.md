# S2SModTemplate

Minimal C# template for building a Slay the Spire 2 mod with Harmony.

This template is intentionally small. It gives you:

- a `net9.0` mod project
- a `[ModInitializer]` bootstrap entrypoint
- Harmony setup
- a simple file and console logger
- a place to add patch classes
- a `mod_manifest.json` copied to the build output

`S2SModTemplate` is a placeholder source name used by the template engine. When you create a project with `dotnet new sts2mod -n MyMod`, the generated solution, project, namespaces, manifest name, logger file name, and Harmony ID are renamed to `MyMod`.

## Requirements

- .NET 9 SDK
- Slay the Spire 2 installed through Steam
- the game files present in Steam's default `steamapps/common` location for your OS, or equivalent paths that match the project file logic

The project references game-managed DLLs directly from the Steam install:

- Windows: `Steam/steamapps/common/Slay the Spire 2/data_sts2_windows_x86_64`
- Linux: `~/.local/share/Steam/steamapps/common/Slay the Spire 2/data_sts2_linuxbsd_x86_64`
- macOS: `~/Library/Application Support/Steam/steamapps/common/Slay the Spire 2/SlayTheSpire2.app/Contents/Resources/...`

If your Steam library is somewhere else, adjust `SteamCommonDir` in `S2SModTemplate/S2SModTemplate.csproj` or the renamed project file produced by the template.

## Project Layout

- `S2SModTemplate.slnx`: solution entrypoint
- `S2SModTemplate/S2SModTemplate.csproj`: target framework, Steam path resolution, DLL references, manifest copy
- `S2SModTemplate/Bootstrap/ModEntry.cs`: mod bootstrap and Harmony initialization
- `S2SModTemplate/Diagnostics/TemplateLog.cs`: best-effort logger writing to console and `<ModName>.log`
- `S2SModTemplate/Patching/ExamplePatches.cs`: placeholder for your Harmony patches
- `S2SModTemplate/mod_manifest.json`: mod metadata copied to output

## First Steps

1. Review `mod_manifest.json` and fill in any metadata you do not want to supply through template parameters.
2. Build the solution once to verify the Steam path resolution on your machine.
3. Add Harmony patches under `S2SModTemplate/Patching/`.

## Build

```bash
dotnet build S2SModTemplate.slnx
```

On a successful build, the output directory will contain:

- your compiled assembly
- `mod_manifest.json`

The project keeps both `sts2.dll` and `0Harmony.dll` as reference-only dependencies and does not copy them into your output.

## Bootstrap Behavior

The template initializes from:

- `[ModInitializer(nameof(Initialize))]` in `S2SModTemplate/Bootstrap/ModEntry.cs`

At startup it:

- logs bootstrap start/end
- preloads Linux native dependencies used by Harmony
- creates a Harmony instance with a template Harmony ID
- applies all patches in the assembly

Keep the Linux preload logic unless you have verified Harmony still initializes correctly without it.

## Adding Patches

Put new Harmony patch classes under `S2SModTemplate/Patching/`.

Example skeleton:

```csharp
using HarmonyLib;

namespace YourModNamespace.Patching;

[HarmonyPatch(typeof(SomeType), nameof(SomeType.SomeMethod))]
public static class SomeTypeSomeMethodPatch
{
    public static void Prefix()
    {
    }
}
```

Prefer one patch class per target or one small coherent behavior.

## Logging

Use `S2SModTemplate/Diagnostics/TemplateLog.cs` for simple diagnostics:

```csharp
TemplateLog.Info("Hello from the mod.");
TemplateLog.Warn("Something looks off.");
TemplateLog.Error("Bootstrap failed.", ex);
```

Logging is best-effort by design. If file writes fail, console logging still continues. The log file name follows the generated mod name, for example `MyMod.log`.
