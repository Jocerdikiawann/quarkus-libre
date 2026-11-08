
import json
import sys
from pathlib import Path
from urllib.parse import unquote


def read_packages(path):
    with open(path, encoding="utf-8") as file:
        sbom = json.load(file)

    packages = {}

    for package in sbom.get("packages", []):
        refs = package.get("externalRefs", [])

        purls = [
            ref["referenceLocator"]
            for ref in refs
            if ref.get("referenceType") == "purl"
            and ref.get("referenceLocator", "").startswith("pkg:apk/")
        ]

        if not purls:
            continue

        purl = purls[0]

        identity = purl.split("?", 1)[0].split("@", 1)[0]

        identity = unquote(identity)

        version = package.get("versionInfo", "UNKNOWN")

        packages[identity] = version

    return packages


def compare(previous, current):
    changes = []

    for identity in sorted(set(previous) | set(current)):
        old = previous.get(identity)
        new = current.get(identity)

        if old == new:
            continue

        if old is None:
            status = "Added"
        elif new is None:
            status = "Removed"
        else:
            status = "Updated"

        changes.append((identity, old or "-", new or "-", status))

    return changes


def main():
    if len(sys.argv) != 3:
        sys.exit(
            "Usage: compare_sbom.py OLD.spdx.json NEW.spdx.json"
        )

    previous = read_packages(sys.argv[1])
    current = read_packages(sys.argv[2])

    changes = compare(previous, current)

    lines = [
        "## Wolfi APK Package Change Report",
        "",
        f"Previous packages: {len(previous)}",
        f"Current packages: {len(current)}",
        f"Changed packages: {len(changes)}",
        "",
        "| Package | Previous | Current | Status |",
        "|---|---|---|---|",
    ]

    for identity, old, new, status in changes:
        lines.append(
            f"| `{identity}` | `{old}` | `{new}` | {status} |"
        )

    report = "\n".join(lines) + "\n"

    print(report)

    Path("package-report.md").write_text(
        report,
        encoding="utf-8",
    )


if __name__ == "__main__":
    main()
