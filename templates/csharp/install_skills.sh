#!/usr/bin/env bash
# Bootstrap project-local Codex + Claude skills by writing the embedded
# skill contents into the project tree. No bundled skills/ folder needed.
#
# Layout produced (relative to PROJECT_ROOT):
#   .codex/skills/sts2-ilspy-reference/SKILL.md
#   .codex/skills/sts2-ilspy-reference/agents/openai.yaml
#   .codex/skills/sts2-ilspy-reference/scripts/decompile_sts2.py
#   .claude/skills/sts2-ilspy-reference/SKILL.md
#   .claude/skills/sts2-ilspy-reference/scripts/decompile_sts2.py
#
# PROJECT_ROOT is the enclosing git repo's top level when this script lives
# inside a git checkout, otherwise the script's own directory.
#
# Usage:
#   ./install_skills.sh                # install both
#   ./install_skills.sh --only codex   # codex|claude|both

set -euo pipefail

TARGET="both"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --only)    TARGET="${2:?--only requires codex|claude|both}"; shift 2 ;;
    -h|--help) sed -n '2,20p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if git_root="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null)"; then
  PROJECT_ROOT="$git_root"
else
  PROJECT_ROOT="$SCRIPT_DIR"
fi

emit() {
  local path="$1"
  mkdir -p "$(dirname "$path")"
  cat > "$path"
  echo "wrote ${path#"$PROJECT_ROOT/"}"
}

emit_skill_md() {
  emit "$1" <<'EOF_SKILL_MD'
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
EOF_SKILL_MD
}

emit_openai_yaml() {
  emit "$1" <<'EOF_OPENAI_YAML'
interface:
  display_name: "STS2 ILSpy Reference"
  short_description: "Decompile sts2.dll for code reference."
  default_prompt: "Use this skill to decompile sts2.dll with ilspycmd and inspect the resulting source as a reference for Slay the Spire 2 modding work."
EOF_OPENAI_YAML
}

emit_decompile_py() {
  emit "$1" <<'EOF_DECOMPILE_PY'
#!/usr/bin/env python3

from __future__ import annotations

import argparse
import os
import platform
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Decompile Slay the Spire 2's sts2.dll with ilspycmd."
    )
    parser.add_argument(
        "--dll",
        type=Path,
        help="Explicit path to sts2.dll. Overrides STS2_DLL_PATH and auto-detection.",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=Path(tempfile.gettempdir()) / "sts2-ilspy-reference" / "sts2",
        help="Output directory for the decompiled project.",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Delete any existing output directory before decompiling.",
    )
    return parser.parse_args()


def resolve_dll_path(explicit: Path | None) -> Path:
    candidates: list[Path] = []

    if explicit is not None:
        candidates.append(explicit.expanduser())

    env_path = os.environ.get("STS2_DLL_PATH")
    if env_path:
        candidates.append(Path(env_path).expanduser())

    home = Path.home()
    system = platform.system()
    machine = platform.machine().lower()

    if system == "Linux":
        candidates.append(
            home
            / ".local/share/Steam/steamapps/common/Slay the Spire 2/data_sts2_linuxbsd_x86_64/sts2.dll"
        )
    elif system == "Darwin":
        steam_common = home / "Library/Application Support/Steam/steamapps/common/Slay the Spire 2"
        if machine in {"arm64", "aarch64"}:
            candidates.append(
                steam_common
                / "SlayTheSpire2.app/Contents/Resources/data_sts2_macos_arm64/sts2.dll"
            )
        if machine in {"x86_64", "amd64"}:
            candidates.append(
                steam_common
                / "SlayTheSpire2.app/Contents/Resources/data_sts2_macos_x86_64/sts2.dll"
            )
        candidates.append(
            steam_common
            / "SlayTheSpire2.app/Contents/Resources/data_sts2_macos_arm64/sts2.dll"
        )
    elif system == "Windows":
        program_files_x86 = os.environ.get("ProgramFiles(x86)")
        program_files = os.environ.get("ProgramFiles")
        for root in (program_files_x86, program_files):
            if root:
                candidates.append(
                    Path(root)
                    / "Steam/steamapps/common/Slay the Spire 2/data_sts2_windows_x86_64/sts2.dll"
                )

    for candidate in candidates:
        if candidate.is_file():
            return candidate.resolve()

    formatted = "\n".join(f"- {candidate}" for candidate in candidates) or "- <none>"
    raise FileNotFoundError(
        "Could not locate sts2.dll.\n"
        "Pass --dll /path/to/sts2.dll or set STS2_DLL_PATH.\n"
        f"Checked:\n{formatted}"
    )


def main() -> int:
    args = parse_args()

    ilspycmd = shutil.which("ilspycmd")
    if ilspycmd is None:
        print("ilspycmd was not found on PATH.", file=sys.stderr)
        print("Install it with: dotnet tool install -g ilspycmd", file=sys.stderr)
        return 1

    try:
        dll_path = resolve_dll_path(args.dll)
    except FileNotFoundError as exc:
        print(str(exc), file=sys.stderr)
        return 1

    output_dir = args.output.expanduser().resolve()
    if output_dir.exists():
        if not args.force:
            print(
                f"Output directory already exists: {output_dir}\n"
                "Use --force to replace it or --output to choose another path.",
                file=sys.stderr,
            )
            return 1
        shutil.rmtree(output_dir)

    output_dir.mkdir(parents=True, exist_ok=True)

    command = [
        ilspycmd,
        "--project",
        "--nested-directories",
        "--disable-updatecheck",
        "--outputdir",
        str(output_dir),
        "--referencepath",
        str(dll_path.parent),
        str(dll_path),
    ]

    print(f"Decompiling: {dll_path}")
    print(f"Output: {output_dir}")
    subprocess.run(command, check=True)
    print(f"Decompiled source ready at: {output_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
EOF_DECOMPILE_PY
}

install_codex() {
  local root="$PROJECT_ROOT/.codex/skills/sts2-ilspy-reference"
  emit_skill_md     "$root/SKILL.md"
  emit_openai_yaml  "$root/agents/openai.yaml"
  emit_decompile_py "$root/scripts/decompile_sts2.py"
  chmod +x "$root/scripts/decompile_sts2.py"
}

install_claude() {
  local root="$PROJECT_ROOT/.claude/skills/sts2-ilspy-reference"
  emit_skill_md     "$root/SKILL.md"
  emit_decompile_py "$root/scripts/decompile_sts2.py"
  chmod +x "$root/scripts/decompile_sts2.py"
}

echo "PROJECT_ROOT=$PROJECT_ROOT"

case "$TARGET" in
  both)   install_codex; install_claude ;;
  codex)  install_codex ;;
  claude) install_claude ;;
  *) echo "--only must be codex|claude|both" >&2; exit 2 ;;
esac
