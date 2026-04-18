# AGENTS.md

## Purpose

This repository is a minimal C# `dotnet new` template pack for building a Slay the Spire 2 mod. Keep changes template-oriented unless the user explicitly asks for a concrete mod feature.

## Repository Layout

- `README.md`: template-pack usage notes, install/create commands, and validation notes.
- `S2SModTemplate.Templates.csproj`: template pack project used by `dotnet pack`.
- `S2SModTemplate/`: source baseline for the minimal mod project.
- `S2SModTemplate/S2SModTemplate.csproj`: `net9.0` source project, Steam game DLL references, and platform-specific managed directory resolution.
- `S2SModTemplate/Bootstrap/ModEntry.cs`: `[ModInitializer]` entrypoint, Harmony bootstrap, Linux native dependency preload.
- `S2SModTemplate/Diagnostics/TemplateLog.cs`: simple file and console logger.
- `S2SModTemplate/Patching/`: place Harmony patch classes here.
- `S2SModTemplate/mod_manifest.json`: mod metadata copied to output.
- `templates/csharp/.template.config/template.json`: .NET template metadata.
- `templates/csharp/`: installable C# template payload.
- `templates/csharp/S2SModTemplate.slnx`: solution file emitted into generated projects.
- `templates/csharp/README.md`: README copied into generated projects.

## Working Rules

- Preserve the template's minimal scope unless asked otherwise. Do not add configuration systems, networking, UI, or extra dependencies by default.
- Treat `S2SModTemplate` as a rename-sensitive placeholder in both the source baseline and the installable template payload. If the user asks to rename the mod or the template placeholder, update all of these together:
  - template `sourceName` behavior in `templates/csharp/.template.config/template.json`
  - generated solution name
  - generated project file name and `<AssemblyName>/<RootNamespace>`
  - namespaces
  - `mod_manifest.json`
  - logger output file name
  - Harmony ID if it embeds the template name
- Keep the game entrypoint on `[ModInitializer(nameof(Initialize))]` unless the user wants a different bootstrap pattern.
- Prefer adding new Harmony patches under `S2SModTemplate/Patching/` instead of expanding `ModEntry.cs`.
- Mirror source-project behavior into `templates/csharp/S2SModTemplate/` when changing generated project contents.
- Keep logging best-effort and non-fatal. This template should still load even if file logging fails.
- Maintain cross-platform path behavior in the project file. Do not hardcode a single OS path unless the user explicitly wants that.
- Keep `sts2.dll` and `0Harmony.dll` as reference-only dependencies unless the user explicitly asks to copy or package them.

## Build And Validation

- Primary validation commands:

```bash
dotnet build S2SModTemplate/S2SModTemplate.csproj
```

```bash
dotnet pack S2SModTemplate.Templates.csproj
```

- If template-generation behavior changes, also validate by installing the packed nupkg into a custom hive, generating a fresh project with `dotnet new sts2mod`, and building that generated project.
- This repository currently has no test project. If you add behavior that is practical to unit test, add tests in a separate project instead of mixing them into the mod assembly.
- A successful local build depends on the referenced game DLLs being resolvable from the Steam install path logic in the project file.

## Change Guidance

- For template cleanup, prefer small, obvious edits over framework-style abstractions.
- When adding patches, keep each patch class focused on one target or one coherent behavior.
- If you introduce a new file that still contains template placeholders, leave a short comment or TODO only when the placeholder would be easy to miss.
- Keep the template pack C#-only unless the user explicitly asks for additional languages or template variants.
- Do not remove the Linux native preload logic without verifying Harmony still initializes correctly on Linux.

## Verified Baseline

As of April 19, 2026, the following succeed in this workspace:

- `dotnet build S2SModTemplate/S2SModTemplate.csproj` with `0` warnings and `0` errors
- `dotnet pack S2SModTemplate.Templates.csproj`
- installing the packed template, generating a fresh `sts2mod` project, and building that generated project with `0` warnings and `0` errors
