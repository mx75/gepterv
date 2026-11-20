#!/usr/bin/env python3
"""Export the ABEL4 fixed-width device database to an aggregated CSV."""
from __future__ import annotations

import csv
import hashlib
import json
from collections import defaultdict
from pathlib import Path

SOURCE = Path("apps_extracted/DATAIO/LIB4/DEVICES.TXT")
OUT_DIR = Path("build")
CSV_PATH = OUT_DIR / "abel4_vendor_parts.csv"
JSON_PATH = OUT_DIR / "abel4_export_summary.json"

EXPECTED = {
    "raw_records": 2521,
    "vendor_part_pairs": 1247,
    "distinct_part_strings": 829,
    "vendors": 26,
    "targets": 264,
    "package_pin_combinations": 42,
}


def parse_record(line: str) -> dict[str, str]:
    # These offsets are the verified ABEL4 DEVICES.TXT fixed-width layout.
    return {
        "vendor": line[0:18].strip(),
        "part": line[18:36].strip(),
        "family": line[36:44].strip(),
        "package_pins": line[44:52].strip(),
        "target": line[52:64].strip(),
        "status": line[64:].strip(),
    }


def joined(values: set[str]) -> str:
    return " | ".join(sorted(values))


def main() -> None:
    raw = SOURCE.read_bytes()
    text = raw.decode("utf-8-sig")
    lines = [line for line in text.splitlines() if line.strip()]
    records = [parse_record(line) for line in lines]

    if any(not row["vendor"] or not row["part"] for row in records):
        raise SystemExit("Validation failed: empty vendor or part field")

    grouped: dict[tuple[str, str], list[dict[str, str]]] = defaultdict(list)
    for row in records:
        grouped[(row["vendor"], row["part"])].append(row)

    actual = {
        "raw_records": len(records),
        "vendor_part_pairs": len(grouped),
        "distinct_part_strings": len({r["part"] for r in records}),
        "vendors": len({r["vendor"] for r in records}),
        "targets": len({r["target"] for r in records}),
        "package_pin_combinations": len({r["package_pins"] for r in records}),
    }
    if actual != EXPECTED:
        raise SystemExit(
            "Validation failed: expected counts do not match source. "
            + json.dumps({"expected": EXPECTED, "actual": actual}, sort_keys=True)
        )

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    columns = [
        "vendor", "part", "family_variants", "package_pin_variants",
        "target_variants", "raw_status_values", "raw_source_record_count",
    ]
    with CSV_PATH.open("w", newline="", encoding="utf-8-sig") as handle:
        writer = csv.DictWriter(handle, fieldnames=columns)
        writer.writeheader()
        for (vendor, part), group in sorted(grouped.items()):
            writer.writerow({
                "vendor": vendor,
                "part": part,
                "family_variants": joined({r["family"] for r in group}),
                "package_pin_variants": joined({r["package_pins"] for r in group}),
                "target_variants": joined({r["target"] for r in group}),
                "raw_status_values": joined({r["status"] for r in group}),
                "raw_source_record_count": len(group),
            })

    summary = {
        **actual,
        "source_path": str(SOURCE),
        "source_sha256": hashlib.sha256(raw).hexdigest(),
        "csv_path": str(CSV_PATH),
        "csv_rows": len(grouped),
        "field_layout": {
            "vendor": "0:18", "part": "18:36", "family": "36:44",
            "package_pins": "44:52", "target": "52:64", "status": "64:end",
        },
        "status_note": "Raw status values only; O/N/R meanings are not inferred.",
    }
    JSON_PATH.write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(summary, indent=2))


if __name__ == "__main__":
    main()
