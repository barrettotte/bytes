"""Generate and validate configured web-ready GLB mirrors of STL files."""

from __future__ import annotations

import argparse
import re
import shutil
import subprocess
import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parent.parent
OUTPUT_ROOT = ROOT / "web-models"
FRONTMATTER = re.compile(r"\A---\s*\n(.*?)\n---\s*\n", re.DOTALL)


class ConfigError(Exception):
    pass


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("generate", "check"))
    parser.add_argument("--force", action="store_true")
    parser.add_argument("--assimp", default="assimp")
    return parser.parse_args()


def patterns(value: object, field: str, readme: Path) -> list[str]:
    if not isinstance(value, list) or not value:
        raise ConfigError(f"{readme.relative_to(ROOT)}: models.{field} must be a non-empty list")
    result = []
    for pattern in value:
        if not isinstance(pattern, str) or not pattern.strip():
            raise ConfigError(f"{readme.relative_to(ROOT)}: models.{field} entries must be text")
        path = Path(pattern)
        if path.is_absolute() or ".." in path.parts:
            raise ConfigError(f"{readme.relative_to(ROOT)}: unsafe model pattern: {pattern}")
        result.append(pattern)
    return result


def configured_sources(readme: Path) -> set[Path]:
    match = FRONTMATTER.match(readme.read_text())
    if not match:
        return set()
    try:
        metadata = yaml.safe_load(match.group(1))
    except yaml.YAMLError as error:
        raise ConfigError(f"{readme.relative_to(ROOT)}: invalid YAML: {error}") from error
    if not isinstance(metadata, dict):
        return set()

    config = metadata.get("models")
    if config is None or config is False:
        return set()
    if config is True:
        include = ["**/*.stl"]
        exclude: list[str] = []
    elif isinstance(config, dict):
        unsupported = set(config) - {"include", "exclude"}
        if unsupported:
            raise ConfigError(
                f"{readme.relative_to(ROOT)}: unsupported models fields: "
                f"{', '.join(sorted(unsupported))}"
            )
        include = patterns(config.get("include"), "include", readme)
        exclude = patterns(config["exclude"], "exclude", readme) if "exclude" in config else []
    else:
        raise ConfigError(f"{readme.relative_to(ROOT)}: models must be true, false, or a mapping")

    found: set[Path] = set()
    for pattern in include:
        matches = [path for path in readme.parent.glob(pattern) if path.is_file()]
        if not matches:
            raise ConfigError(f"{readme.relative_to(ROOT)}: model pattern matched nothing: {pattern}")
        for source in matches:
            if source.suffix.lower() != ".stl":
                raise ConfigError(f"{readme.relative_to(ROOT)}: model is not an STL: {source.name}")
            relative = source.relative_to(readme.parent)
            if not any(relative.match(pattern) for pattern in exclude):
                found.add(source)
    return found


def sources() -> list[Path]:
    configured: set[Path] = set()
    for readme in ROOT.rglob("README.md"):
        if readme.is_relative_to(OUTPUT_ROOT) or ".git" in readme.parts:
            continue
        configured.update(configured_sources(readme))
    return sorted(configured)


def output_for(source: Path) -> Path:
    return (OUTPUT_ROOT / source.relative_to(ROOT)).with_suffix(".glb")


def validate(source: Path, output: Path) -> list[str]:
    if not output.is_file():
        return [f"missing generated model: {output.relative_to(ROOT)}"]
    errors = []
    if output.stat().st_size == 0:
        errors.append(f"empty generated model: {output.relative_to(ROOT)}")
    if output.stat().st_mtime < source.stat().st_mtime:
        errors.append(f"stale generated model: {output.relative_to(ROOT)}")
    return errors


def convert(assimp: str, source: Path, output: Path) -> str | None:
    output.parent.mkdir(parents=True, exist_ok=True)
    temporary = output.with_suffix(".tmp.glb")
    result = subprocess.run(
        [assimp, "export", str(source), str(temporary)],
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0 or not temporary.is_file():
        temporary.unlink(missing_ok=True)
        details = result.stderr.strip() or result.stdout.strip() or "unknown error"
        return f"failed to convert {source.relative_to(ROOT)}: {details}"
    temporary.replace(output)
    return None


def prune_empty_directories() -> None:
    if not OUTPUT_ROOT.exists():
        return
    for directory in sorted(OUTPUT_ROOT.rglob("*"), reverse=True):
        if directory.is_dir():
            try:
                directory.rmdir()
            except OSError:
                pass


def main() -> int:
    args = parse_args()
    try:
        model_sources = sources()
    except (ConfigError, OSError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1

    expected = {output_for(source) for source in model_sources}
    failures: list[str] = []
    converted = 0
    current = 0
    pruned = 0

    if args.command == "generate":
        assimp = shutil.which(args.assimp)
        if not assimp:
            print(f"error: '{args.assimp}' was not found in PATH", file=sys.stderr)
            return 1

        for source in model_sources:
            output = output_for(source)
            if not args.force and output.is_file() and output.stat().st_mtime >= source.stat().st_mtime:
                current += 1
                continue
            error = convert(assimp, source, output)
            if error:
                failures.append(error)
            else:
                converted += 1
                print(f"generated {output.relative_to(ROOT)}")

        if OUTPUT_ROOT.exists():
            for output in OUTPUT_ROOT.rglob("*.glb"):
                if output not in expected:
                    output.unlink()
                    pruned += 1
                    print(f"pruned {output.relative_to(ROOT)}")
            prune_empty_directories()
    else:
        for source in model_sources:
            failures.extend(validate(source, output_for(source)))
        if OUTPUT_ROOT.exists():
            for output in OUTPUT_ROOT.rglob("*.glb"):
                if output not in expected:
                    failures.append(f"orphaned generated model: {output.relative_to(ROOT)}")

    if failures:
        for failure in failures:
            print(f"error: {failure}", file=sys.stderr)
        return 1

    if args.command == "generate":
        print(f"generated {converted} models; skipped {current} current models; pruned {pruned}")
    else:
        print(f"validated {len(model_sources)} configured models")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
