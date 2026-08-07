#!/usr/bin/env python3
"""Generate and validate README indexes for the bytes repository."""

from __future__ import annotations

import argparse
import datetime as dt
import re
import sys
import tomllib
from dataclasses import dataclass
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parent.parent
CONFIG_PATH = ROOT / "bytes.toml"
START = "<!-- bytes:index:start -->"
END = "<!-- bytes:index:end -->"
FRONTMATTER = re.compile(r"\A---\s*\n(.*?)\n---\s*\n", re.DOTALL)
HEADING = re.compile(r"^#\s+(.+?)\s*$", re.MULTILINE)
TABLE = re.compile(r"(?m)^\|[^\n]+\|\n^\|\s*:?-+.*\|(?:\n^\|[^\n]+\|)+")


class ValidationError(Exception):
    pass


@dataclass(frozen=True)
class Item:
    path: str
    title: str
    date: dt.date
    summary: str


@dataclass(frozen=True)
class Collection:
    path: str
    title: str
    summary: str


def load_config() -> dict:
    with CONFIG_PATH.open("rb") as config_file:
        return tomllib.load(config_file)


def normalized_date(value: object, source: Path) -> dt.date:
    if isinstance(value, dt.datetime):
        return value.date()
    if isinstance(value, dt.date):
        return value
    if isinstance(value, str):
        try:
            return dt.date.fromisoformat(value)
        except ValueError:
            pass
    raise ValidationError(f"{source}: 'date' must use YYYY-MM-DD")


def read_item(readme: Path) -> Item:
    text = readme.read_text()
    match = FRONTMATTER.match(text)

    if not match:
        raise ValidationError(f"{readme.relative_to(ROOT)}: missing YAML frontmatter")
    try:
        metadata = yaml.safe_load(match.group(1))
    except yaml.YAMLError as error:
        raise ValidationError(
            f"{readme.relative_to(ROOT)}: invalid YAML: {error}"
        ) from error
    if not isinstance(metadata, dict):
        raise ValidationError(
            f"{readme.relative_to(ROOT)}: frontmatter must be a mapping"
        )

    # Keep item metadata deliberately small so README files remain the source of truth.
    required = {"title", "date", "summary"}
    supported = required | {"models"}
    fields = set(metadata)
    if not required.issubset(fields) or not fields.issubset(supported):
        missing = sorted(required - fields)
        extra = sorted(fields - supported)
        details = []
        if missing:
            details.append(f"missing {', '.join(missing)}")
        if extra:
            details.append(f"unsupported {', '.join(extra)}")
        raise ValidationError(f"{readme.relative_to(ROOT)}: {'; '.join(details)}")

    models = metadata.get("models")
    if models is not None and not isinstance(models, (bool, dict)):
        raise ValidationError(
            f"{readme.relative_to(ROOT)}: 'models' must be true, false, or a mapping"
        )
    if isinstance(models, dict):
        unsupported = set(models) - {"include", "exclude"}
        if unsupported:
            raise ValidationError(
                f"{readme.relative_to(ROOT)}: unsupported models fields: "
                f"{', '.join(sorted(unsupported))}"
            )
        include = models.get("include")
        if not isinstance(include, list) or not include or not all(
            isinstance(pattern, str) and pattern.strip() for pattern in include
        ):
            raise ValidationError(
                f"{readme.relative_to(ROOT)}: models.include must be a non-empty list of patterns"
            )
        exclude = models.get("exclude")
        if exclude is not None and (
            not isinstance(exclude, list)
            or not exclude
            or not all(isinstance(pattern, str) and pattern.strip() for pattern in exclude)
        ):
            raise ValidationError(
                f"{readme.relative_to(ROOT)}: models.exclude must be a non-empty list of patterns"
            )

    for field in ("title", "summary"):
        if not isinstance(metadata[field], str) or not metadata[field].strip():
            raise ValidationError(
                f"{readme.relative_to(ROOT)}: '{field}' must be non-empty text"
            )
        if "|" in metadata[field] or "\n" in metadata[field]:
            raise ValidationError(
                f"{readme.relative_to(ROOT)}: '{field}' cannot contain '|' or newlines"
            )

    relative = readme.parent.relative_to(ROOT).as_posix()
    return Item(
        relative,
        metadata["title"].strip(),
        normalized_date(metadata["date"], readme),
        metadata["summary"].strip(),
    )


def read_collection(path: Path) -> Collection:
    readme = path / "README.md"
    if not readme.is_file():
        raise ValidationError(
            f"{path.relative_to(ROOT)}/README.md: missing collection README"
        )

    text = readme.read_text()
    heading = HEADING.search(text)
    if not heading:
        raise ValidationError(f"{readme.relative_to(ROOT)}: missing level-one heading")

    # Collection metadata comes from its handwritten heading and first paragraph.
    # Ignore the generated block, which may also contain headings or paragraphs.
    content = text[heading.end() :]
    content = content.split(START, 1)[0]
    paragraphs = [
        part.strip() for part in re.split(r"\n\s*\n", content) if part.strip()
    ]
    if not paragraphs:
        raise ValidationError(f"{readme.relative_to(ROOT)}: missing collection summary")

    summary = " ".join(paragraphs[0].split())
    return Collection(
        path.relative_to(ROOT).as_posix(), heading.group(1).strip(), summary
    )


def discover(config: dict) -> tuple[dict[str, Collection], dict[str, Item]]:
    excluded = tuple(config.get("exclude", []))
    index_paths = {str(path).rstrip("/") or "." for path in config["indexes"]}
    collections: dict[str, Collection] = {}
    for relative in index_paths:
        collections[relative] = read_collection(
            ROOT if relative == "." else ROOT / relative
        )

    items: dict[str, Item] = {}
    for readme in ROOT.rglob("README.md"):
        relative = readme.parent.relative_to(ROOT).as_posix()
        if relative == "." or relative in index_paths:
            continue
        if any(
            relative == path or relative.startswith(f"{path}/") for path in excluded
        ):
            continue
        item = read_item(readme)
        items[item.path] = item

    # Configured items cover the occasional indexed file that has no README.
    for raw in config.get("items", []):
        path = raw["path"]
        target = ROOT / path
        if not target.is_file():
            raise ValidationError(f"bytes.toml: configured item does not exist: {path}")
        item = Item(
            path,
            raw["title"],
            normalized_date(raw["date"], CONFIG_PATH),
            raw["summary"],
        )
        items[path] = item

    titles: dict[str, str] = {}
    for item in items.values():
        key = item.title.casefold()
        if key in titles:
            raise ValidationError(
                f"duplicate title '{item.title}': {titles[key]} and {item.path}"
            )
        titles[key] = item.path

    # Every direct child of a managed index must participate in the README hierarchy.
    for relative in index_paths - {"."}:
        directory = ROOT / relative
        for child in directory.iterdir():
            if (
                child.is_dir()
                and not child.name.startswith(".")
                and not (child / "README.md").is_file()
            ):
                raise ValidationError(
                    f"{child.relative_to(ROOT)}/README.md: missing item README"
                )
    return collections, items


def link_from(index: str, target: str, directory: bool) -> str:
    base = Path(".") if index == "." else Path(index)
    relative = Path(target).relative_to(base).as_posix()
    return f"./{relative}{'/' if directory else ''}"


def table_for(
    index: str, collections: dict[str, Collection], items: dict[str, Item]
) -> str:
    rows: list[tuple[dt.date | None, str, str, str]] = []
    if index == ".":
        # The root is a recursive master list; nested indexes show direct children only.
        for item in items.values():
            rows.append((item.date, item.path, item.title, item.summary))
    else:
        prefix = f"{index}/"
        for item in items.values():
            remainder = item.path.removeprefix(prefix)
            if item.path.startswith(prefix) and "/" not in remainder:
                rows.append((item.date, item.path, item.title, item.summary))

        for path, collection in collections.items():
            if path == "." or not path.startswith(prefix):
                continue
            remainder = path.removeprefix(prefix)
            if "/" not in remainder:
                rows.append((None, path, collection.title, collection.summary))

    # Stable sorting keeps equal dates alphabetical and puts undated collections last.
    rows.sort(key=lambda row: row[2].casefold())
    rows.sort(key=lambda row: (row[0] is not None, row[0] or dt.date.min), reverse=True)
    lines = ["| Item | Date | Description |", "| --- | --- | --- |"]
    for date, path, title, summary in rows:
        is_directory = (ROOT / path).is_dir()
        link = link_from(index, path, is_directory)
        date_text = date.isoformat() if date else "N/A"
        lines.append(f"| [{title}]({link}) | {date_text} | {summary} |")
    return "\n".join(lines)


def rendered_readme(index: str, table: str) -> tuple[Path, str]:
    readme = ROOT / "README.md" if index == "." else ROOT / index / "README.md"
    current = readme.read_text()
    generated = f"{START}\n{table}\n{END}"

    # Only replace content inside the markers so handwritten introductions survive.
    if START in current or END in current:
        if (
            current.count(START) != 1
            or current.count(END) != 1
            or current.index(START) > current.index(END)
        ):
            raise ValidationError(
                f"{readme.relative_to(ROOT)}: malformed generated-index markers"
            )
        updated = (
            current[: current.index(START)]
            + generated
            + current[current.index(END) + len(END) :]
        )
    else:
        # The legacy-table fallback makes the first generation a one-step migration.
        legacy = TABLE.search(current)
        if not legacy:
            updated = current.rstrip() + "\n\n" + generated + "\n"
        else:
            updated = current[: legacy.start()] + generated + current[legacy.end() :]
    return readme, updated


def run(command: str) -> int:
    try:
        config = load_config()
        collections, items = discover(config)
        outputs = [
            rendered_readme(index, table_for(index, collections, items))
            for index in config["indexes"]
        ]
    except (KeyError, OSError, tomllib.TOMLDecodeError, ValidationError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1

    # Both commands render in memory; only generate is allowed to write the result.
    stale = []
    for path, expected in outputs:
        if path.read_text() == expected:
            continue
        stale.append(path.relative_to(ROOT))
        if command == "generate":
            path.write_text(expected)
    if stale:
        if command == "check":
            for path in stale:
                print(f"stale: {path}", file=sys.stderr)
            print("run `make generate` to update README indexes", file=sys.stderr)
            return 1
        for path in stale:
            print(f"updated {path}")
    else:
        print("README indexes are current")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("command", choices=("generate", "check"))
    return run(parser.parse_args().command)


if __name__ == "__main__":
    raise SystemExit(main())
