---
name: sts2-ilspy-reference
description: Decompile `sts2.dll` with `ilspycmd` and inspect the resulting C# source as a local reference for Slay the Spire 2 modding. Use when Codex needs to understand game types, methods, fields, namespaces, or call flow before writing Harmony patches, bootstrap code, or other mod code against the game's managed DLLs.
---

# STS2 ILSpy Reference

Use this skill to build a searchable local source reference from `sts2.dll` before making code changes.

## Workflow

1. Confirm `ilspycmd` is installed.
2. Run `scripts/decompile_sts2.py` to resolve the DLL path and decompile it into a local output directory.
3. Search the decompiled output with `rg` to inspect target types and methods.
4. Treat the decompiled output as a reference, not as hand-written upstream source.

## Quick Start

From the skill folder:

```bash
python3 scripts/decompile_sts2.py
```

Common variants:

```bash
python3 scripts/decompile_sts2.py --force
python3 scripts/decompile_sts2.py --output /tmp/sts2-ref
python3 scripts/decompile_sts2.py --dll "/custom/path/to/sts2.dll"
```

After decompiling, search with `rg`:

```bash
rg "SomeTypeName" /tmp/sts2-ilspy-reference/sts2
rg "SomeMethod" /tmp/sts2-ilspy-reference/sts2
```

## Default Path Resolution

Prefer the bundled script instead of hardcoding paths. It resolves in this order:

1. `--dll`
2. `STS2_DLL_PATH`
3. Steam default install paths for the current OS

The script currently checks:

- Linux: `~/.local/share/Steam/steamapps/common/Slay the Spire 2/data_sts2_linuxbsd_x86_64/sts2.dll`
- macOS arm64: `~/Library/Application Support/Steam/steamapps/common/Slay the Spire 2/SlayTheSpire2.app/Contents/Resources/data_sts2_macos_arm64/sts2.dll`
- macOS x64: `~/Library/Application Support/Steam/steamapps/common/Slay the Spire 2/SlayTheSpire2.app/Contents/Resources/data_sts2_macos_x86_64/sts2.dll`
- Windows: `%ProgramFiles(x86)%\Steam\steamapps\common\Slay the Spire 2\data_sts2_windows_x86_64\sts2.dll` and `%ProgramFiles%\Steam\steamapps\common\Slay the Spire 2\data_sts2_windows_x86_64\sts2.dll`

## Guidance

- Re-run with `--force` after a game update or if the DLL timestamp changes.
- Keep searches focused. Use `rg` against type names, method names, enum names, and namespaces.
- Check surrounding types and call sites, not just the first matching method.
- Expect decompiler artifacts such as synthesized names or formatting differences.
- Do not copy large chunks of decompiled code into the mod. Use it to understand APIs and behavior, then write minimal original mod code.

## Failure Handling

- If `ilspycmd` is missing, install it first.
- If the script cannot find the DLL automatically, pass `--dll` explicitly.
- If decompilation fails because dependencies are missing, verify the DLL lives next to the rest of the game's managed assemblies. The script passes the DLL directory as the reference path to `ilspycmd`.
