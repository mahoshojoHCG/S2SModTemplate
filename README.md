# S2SModTemplate

Minimal C# template for building a Slay the Spire 2 mod with Harmony.

This repository now contains two things:

- the template source project under `S2SModTemplate/`
- a real `dotnet new` template definition under `templates/csharp/.template.config/template.json`

That means this is no longer just a sample project layout. You can pack or install it as a standard .NET template, similar to the structure used by `AvaloniaUI/avalonia-dotnet-templates`, while keeping a single C# template only.

## Install And Create

Install the template locally from the repo root:

```bash
dotnet new install .
```

Create a new mod:

```bash
dotnet new sts2mod -n MyMod -o MyMod
```

Optional manifest parameters:

```bash
dotnet new sts2mod -n MyMod -o MyMod --ModAuthor "YourName" --ModDescription "My mod." --ModVersion "0.1.0"
```

The template currently exposes one C# project template:

- template name: `Slay the Spire 2 Mod`
- short name: `sts2mod`
- language: `C#`

## Pack The Template

Pack the distributable template package:

```bash
dotnet pack S2SModTemplate.Templates.csproj
```

The package is written to:

```text
bin/Release/S2SModTemplate.Templates.0.1.0.nupkg
```

## Repo Layout

- `S2SModTemplate.slnx`: solution entrypoint for the template source project
- `S2SModTemplate/S2SModTemplate.csproj`: the minimal mod project used as the source baseline
- `S2SModTemplate.Templates.csproj`: template pack project for `dotnet pack`
- `templates/csharp/`: installable C# template payload and `.template.config`
- `templates/csharp/S2SModTemplate/`: content that becomes the generated mod project
- `templates/csharp/README.md`: README copied into generated projects

`S2SModTemplate` remains the placeholder source name for the template engine. `template.json` replaces it across file names, namespaces, assembly name, logger file name, manifest name, and the Harmony ID.

This repo also includes an optional Codex skill under `skills/sts2-ilspy-reference`, but that skill is not part of the generated mod template.

## Template Contents

The generated project gives you:

- a `net9.0` mod project
- a `[ModInitializer]` bootstrap entrypoint
- Harmony setup
- a simple file and console logger
- a place to add patch classes
- a `mod_manifest.json` copied to the build output

The template references game-managed DLLs directly from the Steam install:

- Windows: `Steam/steamapps/common/Slay the Spire 2/data_sts2_windows_x86_64`
- Linux: `~/.local/share/Steam/steamapps/common/Slay the Spire 2/data_sts2_linuxbsd_x86_64`
- macOS: `~/Library/Application Support/Steam/steamapps/common/Slay the Spire 2/SlayTheSpire2.app/Contents/Resources/...`

If your Steam library is somewhere else, adjust `SteamCommonDir` in the generated `.csproj`.

## Validation

```bash
dotnet build S2SModTemplate.slnx
```

```bash
dotnet pack S2SModTemplate.Templates.csproj
```

On a successful build, the output directory will contain:

- your compiled assembly
- `mod_manifest.json`

The project keeps both `sts2.dll` and `0Harmony.dll` as reference-only dependencies and does not copy them into your output.

As of April 18, 2026 in this workspace:

- `dotnet build S2SModTemplate.slnx` succeeds with `0` warnings and `0` errors
- `dotnet pack S2SModTemplate.Templates.csproj` succeeds
- installing the packed template and creating a fresh `sts2mod` project succeeds
- the generated project builds with `0` warnings and `0` errors

## Optional Codex Skill

This repo includes a repo-local Codex skill for decompiling `sts2.dll` with `ilspycmd` and using the result as a searchable reference while modding:

- `skills/sts2-ilspy-reference/SKILL.md`
