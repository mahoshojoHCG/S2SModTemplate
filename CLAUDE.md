# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A `dotnet new` template package (`S2SModTemplate.Templates`) that scaffolds Harmony-based C# mods for Slay the Spire 2. There is no runtime code at the repo root — everything ships inside `templates/csharp/` and is rewritten by the `dotnet new` engine when a user runs `dotnet new sts2mod`.

## Common commands

```bash
# Pack the template nupkg
dotnet pack S2SModTemplate.Templates.csproj
# → bin/Release/S2SModTemplate.Templates.0.1.0.nupkg

# Install the template from the local checkout (re-run after edits to templates/)
dotnet new install .
dotnet new uninstall S2SModTemplate.Templates    # if reinstalling

# Smoke-test the template end-to-end
dotnet new sts2mod -n MyMod -o /tmp/MyMod
cd /tmp/MyMod && dotnet build
```

There is no test suite. Verification is `dotnet new sts2mod` + `dotnet build` of the generated project against a real Steam install of Slay the Spire 2.

## Architecture

**Two layers, both important.** The repo *itself* is a NuGet template package; the *generated* project is a Harmony mod. Edits land in `templates/csharp/` 99% of the time — the root only contains the pack csproj.

### Template engine (`templates/csharp/.template.config/template.json`)

- `sourceName` is `S2SModTemplate` — every occurrence of that string in file paths and file contents is rewritten to the user's `-n` value. Renaming the placeholder requires changing this field.
- Token-replacement placeholders embedded in template files (do not rename without updating `template.json`):
  - `MOD_NAMESPACE` — root C# namespace (defaults to project name)
  - `MOD_HARMONY_ID` — Harmony instance id (defaults to `sts2.<name>`)
  - `MOD_DISPLAY_NAME`, `MOD_AUTHOR`, `MOD_DESCRIPTION`, `MOD_VERSION` — manifest fields
  - The `*_PLACEHOLDER_DO_NOT_USE` tokens exist so empty user input falls through the `coalesce` generators to a sane default.

### Generated mod project (`templates/csharp/S2SModTemplate.csproj`)

- Targets `net9.0`, references game DLLs (`sts2.dll`, `0Harmony.dll`, `GodotSharp.dll`, `Steamworks.NET.dll`) directly from the local Steam install. `<Private>false</Private>` on `sts2`/`0Harmony` keeps them out of the build output.
- `SteamCommonDir` / `SteamManagedDir` are resolved per-OS in MSBuild (Windows / Linux / macOS arm64+x64). Users override `SteamCommonDir` if their library is elsewhere.
- `S2SModTemplate.json` is the mod manifest, copied to output. The filename is renamed by `sourceName` substitution.

### Bootstrap (`templates/csharp/Bootstrap/ModEntry.cs`)

- Single `[ModInitializer]` entry point that runs `Harmony.PatchAll` on its own assembly.
- Uses `Interlocked.Exchange` to guard against double-init.
- On Linux, dlopens `libgcc_s.so.1` and `libunwind.so.8` with `RTLD_GLOBAL` *before* Harmony patches. Harmony's transpiler path silently fails without this — keep the preload if you refactor `ModEntry`.

### `install_skills.sh`

Self-contained bootstrap shipped *inside* the template. When a user runs it in their generated project, it writes `sts2-ilspy-reference` skill files into `.codex/skills/` and `.claude/skills/`. The skill payloads are inlined as heredocs in the script — there is no `skills/` source folder in this repo. Editing the skill means editing the heredocs.

## Conventions

- Don't add runtime code at the repo root. The deleted `S2SModTemplate/` directory at the root is intentional — the source of truth lives under `templates/csharp/`.
- When adding a new templated value, wire it through `template.json` symbols (parameter + optional `coalesce` generator) and use a `MOD_*` placeholder string in the file content.
- When adding a new file under `templates/csharp/`, it is automatically picked up by `<Content Include="templates\**\*" />` in `S2SModTemplate.Templates.csproj` (no manual registration needed).
