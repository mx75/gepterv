#!/usr/bin/env python3
"""Export device evidence from the legacy PLD tool packages.

The exporter deliberately keeps compiler support, device-database presence,
simulation-only lists, examples, and documentation mentions as separate
evidence classes. It does not infer programmer-hardware compatibility.
"""
from __future__ import annotations

import csv
import hashlib
import json
import re
from collections import Counter
from pathlib import Path

ROOT = Path("apps_extracted")
OUT = Path("build")
CSV_OUT = OUT / "legacy_pld_device_evidence.csv"
JSON_OUT = OUT / "legacy_pld_export_summary.json"

ROWS: list[dict[str, str]] = []
SOURCE_HASHES: dict[str, str] = {}


def read_text(path: Path) -> str:
    raw = path.read_bytes()
    SOURCE_HASHES[path.as_posix()] = hashlib.sha256(raw).hexdigest()
    for encoding in ("utf-8-sig", "cp1252", "latin-1"):
        try:
            return raw.decode(encoding).replace("\x1a", "")
        except UnicodeDecodeError:
            pass
    return raw.decode("latin-1", errors="replace")


def add(tool: str, device: str, evidence: str, source: Path,
        details: str = "", role: str = "device_support_evidence") -> None:
    ROWS.append({
        "tool": tool,
        "device": device.strip(),
        "evidence_status": evidence,
        "evidence_role": role,
        "source_path": source.as_posix(),
        "details": details.strip(),
    })


def parse_cupl(tool: str, source: Path) -> None:
    text = read_text(source)
    found = 0
    for line in text.splitlines():
        m = re.match(r"^\s*([A-Za-z0-9][A-Za-z0-9_+./-]*)\s+(\d{2})\s+(\d{1,3})\s+(\d+)\s+(\d+)\s*$", line)
        if not m:
            continue
        device, revision, pins, fuses, pterms = m.groups()
        add(tool, device, "device_library_list_presence", source,
            f"revision={revision}; pins={pins}; fuses={fuses}; pterms={pterms}",
            "compiler_device_library_listing")
        found += 1
    if not found:
        raise SystemExit(f"No CUPL records parsed from {source}")


def parse_machxl() -> None:
    directory = ROOT / "MACHXL" / "DAT"
    readme = ROOT / "MACHXL" / "README.DOC"
    doc = read_text(readme)
    explicit = set()
    # README uses compact slash lists such as MACH355/435/445/465 and
    # JEDEC ON MACH110/111/120/...; expand each member explicitly.
    for match in re.finditer(r"\\bMACH\\s*(\\d{3}(?:/\\d{3})*)", doc, re.I):
        explicit.update("MACH" + part for part in match.group(1).split("/"))
    for path in sorted(directory.glob("*.DEV")):
        SOURCE_HASHES[path.as_posix()] = hashlib.sha256(path.read_bytes()).hexdigest()
        device = path.stem.upper()
        status = "explicit_documented_compiler_support" if device in explicit else "device_database_presence"
        add("MACHXL 2.0", device, status, path,
            "README.DOC names device" if device in explicit else "A .DEV device-definition file exists; README does not explicitly list it.",
            "compiler_support" if device in explicit else "device_definition")


def parse_palasm2() -> None:
    # CHIP declarations in sample PDS designs describe example targets only.
    for path in sorted((ROOT / "PALASM2").glob("*.PDS")):
        text = read_text(path)
        for m in re.finditer(r"(?im)^\s*CHIP\s+\S+\s+([A-Za-z0-9_./+-]+)", text):
            add("PALASM 2", m.group(1), "example_design_target_reference", path,
                "Target named by a CHIP declaration in a supplied example; this is not proof of compiler support.",
                "example_source")


def parse_palasm4() -> None:
    sim = ROOT / "PALASM4" / "DAT" / "OLDPART.PAL"
    text = read_text(sim)
    for token in re.findall(r"(?im)^\s*([^\r\n<]+)", text):
        if "<SIM>" in token or "devices for SIM" in token.lower():
            continue
        for device in re.findall(r"\b[A-Za-z0-9]+\b", token):
            if device.upper() not in {"SIM"}:
                add("PALASM 4", device, "simulator_only", sim,
                    "Listed in OLDPART.PAL under the <SIM> device list.", "simulator_device_list")

    docs = ROOT / "PALASM4" / "DOC" / "IREF"
    for filename in ("PAL_DEV.HLP", "MACH_DEV.HLP"):
        path = docs / filename
        if not path.exists():
            continue
        text = read_text(path)
        pattern = r"\b(?:PALCE?|PLS|MACH)\s*[A-Z0-9]+\b"
        for match in re.finditer(pattern, text, re.I):
            device = re.sub(r"\s+", "", match.group(0)).upper()
            add("PALASM 4", device, "documentation_only", path,
                "Device name occurs in a PALASM4 help document; not a compiler-support assertion.",
                "documentation_reference")


def parse_palce() -> None:
    directory = ROOT / "PALCE271"
    readme = directory / "README!"
    doc = read_text(readme)
    explicit_names = set()
    # The README explicitly names PEEL22V10AZ and PA7140 in its version notes.
    for name in ("PEEL22V10AZ", "PA7140"):
        if name in doc.upper():
            explicit_names.add(name)
    for path in sorted(directory.glob("*.PSF")):
        SOURCE_HASHES[path.as_posix()] = hashlib.sha256(path.read_bytes()).hexdigest()
        stem = path.stem.upper()
        # PSF filenames use ANEW prefixes and abbreviated suffixes. Preserve
        # the literal filename as the primary device identifier.
        device = stem
        add("PLACE / PALCE 2.71", device, "device_definition_presence", path,
            "PSF architecture/device-definition file; filename retained literally.",
            "device_definition")
    for name in sorted(explicit_names):
        add("PLACE / PALCE 2.71", name, "explicit_documented_support", readme,
            "Explicitly named in README version notes.", "compiler_support")


def parse_pldshell() -> None:
    directory = ROOT / "PLDSHELL"
    readme = directory / "README"
    text = read_text(readme)
    section = re.search(r"(?is)PLDshell Plus Device Support\s*-+\s*(.*?)\s*Intel device name synonyms", text)
    if not section:
        raise SystemExit("Could not locate PLDshell device support section")
    block = section.group(1)
    current_family = ""
    for line in block.splitlines():
        stripped = line.strip()
        if not stripped:
            continue
        if "Family:" in stripped:
            current_family = stripped
            continue
        if stripped.lower().startswith(("classic", "flexlogic")):
            current_family = stripped.rstrip(":")
            continue
        for device in re.findall(r"\b(?:EPX?\d+[A-Z0-9]*)\b", stripped, re.I):
            add("PLDShell Plus 5", device.upper(), "explicit_documented_support", readme,
                f"README device-support list; family={current_family}", "compiler_support")
    # JDB files are catalogued as database files, not automatically decoded
    # into device rows. Their filenames are inventory evidence only.
    for path in sorted(directory.glob("*.JDB")):
        SOURCE_HASHES[path.as_posix()] = hashlib.sha256(path.read_bytes()).hexdigest()
        add("PLDShell Plus 5", path.stem.upper(), "device_database_file_presence", path,
            "JDB file present; internal format/content not decoded by this exporter.",
            "device_database_inventory")


def parse_abel5() -> None:
    path = ROOT / "ABEL" / "LIB5" / "ABEL5EDU.DEV"
    if path.exists():
        raw = path.read_bytes()
        SOURCE_HASHES[path.as_posix()] = hashlib.sha256(raw).hexdigest()
        add("ABEL 5", "[unparsed device database]", "unparsed_binary_device_database", path,
            f"Binary/non-text database; {len(raw)} bytes. No device names inferred.",
            "unparsed_database")


def main() -> None:
    parse_cupl("CUPL 3.2", ROOT / "CUPL" / "0.LST")
    parse_cupl("CUPL 4.0", ROOT / "CUPL4" / "0DEV.LST")
    parse_machxl()
    parse_palasm2()
    parse_palasm4()
    parse_palce()
    parse_pldshell()
    parse_abel5()

    OUT.mkdir(parents=True, exist_ok=True)
    columns = ["tool", "device", "evidence_status", "evidence_role", "source_path", "details"]
    with CSV_OUT.open("w", newline="", encoding="utf-8-sig") as handle:
        writer = csv.DictWriter(handle, fieldnames=columns)
        writer.writeheader()
        writer.writerows(sorted(ROWS, key=lambda r: (r["tool"], r["device"], r["evidence_status"], r["source_path"])))

    by_tool = Counter(r["tool"] for r in ROWS)
    by_status = Counter(r["evidence_status"] for r in ROWS)
    summary = {
        "export": "legacy_pld_device_evidence",
        "rows": len(ROWS),
        "rows_by_tool": dict(sorted(by_tool.items())),
        "rows_by_evidence_status": dict(sorted(by_status.items())),
        "source_files_hashed": len(SOURCE_HASHES),
        "source_sha256": dict(sorted(SOURCE_HASHES.items())),
        "csv_path": str(CSV_OUT),
        "csv_rows": len(ROWS),
        "method_notes": [
            "Compiler support, device-definition presence, simulator-only entries, documentation references and example-design targets are separate evidence classes.",
            "No programmer hardware compatibility is inferred.",
            "ABEL5EDU.DEV is inventoried but not decoded.",
            "PALASM2 PDS CHIP declarations are example targets, not proof of compiler support.",
            "PLDShell JDB files are inventoried by filename; their internal content is not decoded.",
            "PLACE PSF filenames are retained literally; no undocumented filename-to-part aliases are inferred."
        ],
        "not_included": {
            "OPAL_or_OPALjr": "No OPAL/OPALjr source directory or files were identified in the current repository tree; add them when supplied.",
            "ABEL5_fit_external_dependencies": "Not classified from the device database alone; fitter/toolchain dependencies require separate documentation or executable-pipeline evidence."
        }
    }
    JSON_OUT.write_text(json.dumps(summary, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(json.dumps({"rows": len(ROWS), "rows_by_tool": dict(by_tool), "rows_by_evidence_status": dict(by_status)}, indent=2))


if __name__ == "__main__":
    main()
