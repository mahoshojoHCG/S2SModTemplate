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
