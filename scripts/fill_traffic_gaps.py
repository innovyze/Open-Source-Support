"""
Fill traffic data gaps in views.csv and clones.csv from a raw GitHub traffic event log.

Usage:
    python scripts/fill_traffic_gaps.py <path-to-raw-log.csv>

The script runs in 5 phases with checkpoint assertions at each stage.
If any checkpoint fails, execution halts before modifying files.
"""

import argparse
import csv
import sys
from collections import defaultdict
from datetime import date, timedelta
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
VIEWS_CSV = REPO_ROOT / "data" / "views.csv"
CLONES_CSV = REPO_ROOT / "data" / "clones.csv"

GAP_START = date(2025, 11, 15)
GAP_END = date(2026, 1, 7)
OVERLAP_START = date(2026, 1, 8)
OVERLAP_END = date(2026, 1, 15)


def date_range(start: date, end: date):
    current = start
    while current <= end:
        yield current
        current += timedelta(days=1)


def read_existing_csv(path: Path) -> dict[date, tuple[int, int]]:
    rows = {}
    with open(path, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            d = date.fromisoformat(row["_date"])
            col2 = list(row.keys())[1]
            col3 = list(row.keys())[2]
            rows[d] = (int(row[col2]), int(row[col3]))
    return rows


# ── Phase 1: Read raw log and aggregate ──────────────────────────────────────

def phase1_aggregate(raw_log_path: Path):
    print("=" * 60)
    print("PHASE 1: Read and aggregate raw event log")
    print("=" * 60)

    daily_views: dict[date, int] = defaultdict(int)
    daily_clones: dict[date, int] = defaultdict(int)
    skipped = 0
    total = 0

    with open(raw_log_path, newline="", encoding="utf-8") as f:
        reader = csv.reader(f)
        header = next(reader)
        print(f"  Header: {header}")

        for row in reader:
            total += 1
            if len(row) < 4:
                skipped += 1
                continue

            timestamp, event_type, _repo, clone_flag = row[0], row[1], row[2], row[3]

            try:
                d = date.fromisoformat(timestamp[:10])
            except ValueError:
                skipped += 1
                continue

            if event_type == "page_view":
                daily_views[d] += 1
            elif event_type == "fetch" and clone_flag == "true":
                daily_clones[d] += 1

    print(f"  Total rows: {total}")
    print(f"  Skipped rows: {skipped}")
    print(f"  Days with views: {len(daily_views)}")
    print(f"  Days with clones: {len(daily_clones)}")
    print(f"  Date range: {min(daily_views.keys())} to {max(daily_views.keys())}")

    return daily_views, daily_clones


def phase1_validate(daily_views, daily_clones):
    print("\n  Checkpoint 1: Cross-validating overlap dates (Jan 8-15)...")

    existing_views = read_existing_csv(VIEWS_CSV)
    existing_clones = read_existing_csv(CLONES_CSV)

    TOLERANCE = 1
    warnings = []
    errors = []

    for d in date_range(OVERLAP_START, OVERLAP_END):
        raw_v = daily_views.get(d, 0)
        csv_v = existing_views.get(d, (0, 0))[0]
        diff_v = abs(raw_v - csv_v)
        if diff_v > TOLERANCE:
            errors.append(f"  Views {d}: raw={raw_v} csv={csv_v} (diff={diff_v})")
        elif diff_v > 0:
            warnings.append(f"  Views {d}: raw={raw_v} csv={csv_v} (diff={diff_v}, within tolerance)")

        raw_c = daily_clones.get(d, 0)
        csv_c = existing_clones.get(d, (0, 0))[0]
        diff_c = abs(raw_c - csv_c)
        if diff_c > TOLERANCE:
            errors.append(f"  Clones {d}: raw={raw_c} csv={csv_c} (diff={diff_c})")
        elif diff_c > 0:
            warnings.append(f"  Clones {d}: raw={raw_c} csv={csv_c} (diff={diff_c}, within tolerance)")

    if warnings:
        print("  Warnings (within tolerance):")
        for w in warnings:
            print(f"    {w}")

    if errors:
        print("  FAILED - Mismatches beyond tolerance:")
        for e in errors:
            print(f"    {e}")
        sys.exit(1)

    print("  PASSED - All overlap dates match within tolerance.")


# ── Phase 2: Generate gap rows ───────────────────────────────────────────────

def phase2_generate(daily_views, daily_clones):
    print("\n" + "=" * 60)
    print("PHASE 2: Generate gap rows")
    print("=" * 60)

    existing_views = read_existing_csv(VIEWS_CSV)
    existing_clones = read_existing_csv(CLONES_CSV)

    gap_days = list(date_range(GAP_START, GAP_END))
    print(f"  Gap period: {GAP_START} to {GAP_END} ({len(gap_days)} days)")

    view_rows = []
    clone_rows = []

    for d in gap_days:
        if d in existing_views:
            print(f"  ABORT - {d} already exists in views.csv")
            sys.exit(1)
        if d in existing_clones:
            print(f"  ABORT - {d} already exists in clones.csv")
            sys.exit(1)

        view_rows.append((d, daily_views.get(d, 0), 0))
        clone_rows.append((d, daily_clones.get(d, 0), 0))

    total_views = sum(r[1] for r in view_rows)
    total_clones = sum(r[1] for r in clone_rows)

    print(f"  Generated {len(view_rows)} view rows (total: {total_views})")
    print(f"  Generated {len(clone_rows)} clone rows (total: {total_clones})")

    print("\n  Checkpoint 2: Validating generated data...")

    errors = []
    if len(view_rows) != 54:
        errors.append(f"Expected 54 view rows, got {len(view_rows)}")
    if len(clone_rows) != 54:
        errors.append(f"Expected 54 clone rows, got {len(clone_rows)}")
    if total_views < 5000 or total_views > 12000:
        errors.append(f"Total views {total_views} outside expected range 5000-12000")
    if total_clones < 50 or total_clones > 500:
        errors.append(f"Total clones {total_clones} outside expected range 50-500")

    if errors:
        print("  FAILED:")
        for e in errors:
            print(f"    {e}")
        sys.exit(1)

    print("  PASSED - 54 rows, totals within expected range.")
    return view_rows, clone_rows


# ── Phase 3: Merge into CSVs ────────────────────────────────────────────────

def phase3_merge(view_rows, clone_rows):
    print("\n" + "=" * 60)
    print("PHASE 3: Merge into CSV files")
    print("=" * 60)

    merge_into_csv(
        VIEWS_CSV,
        "_date,total_views,unique_views",
        view_rows,
        "views"
    )

    merge_into_csv(
        CLONES_CSV,
        "_date,total_clones,unique_clones",
        clone_rows,
        "clones"
    )


def merge_into_csv(path: Path, header: str, new_rows, label: str):
    existing = read_existing_csv(path)
    original_count = len(existing)

    for d, total, unique in new_rows:
        if d in existing:
            print(f"  ABORT - Duplicate date {d} in {label}")
            sys.exit(1)
        existing[d] = (total, unique)

    sorted_dates = sorted(existing.keys())

    with open(path, "w", newline="", encoding="utf-8") as f:
        f.write(header + "\n")
        for d in sorted_dates:
            total, unique = existing[d]
            f.write(f"{d},{total},{unique}\n")

    new_count = len(sorted_dates)
    print(f"  {label}.csv: {original_count} -> {new_count} rows (+{new_count - original_count})")

    phase3_validate(path, header, sorted_dates, label)


def phase3_validate(path: Path, header: str, expected_dates, label: str):
    print(f"\n  Checkpoint 3 ({label}): Validating written file...")

    reread = read_existing_csv(path)
    reread_dates = sorted(reread.keys())

    if reread_dates != expected_dates:
        print(f"  FAILED - Re-read dates don't match written dates for {label}")
        sys.exit(1)

    for i in range(1, len(reread_dates)):
        if reread_dates[i] <= reread_dates[i - 1]:
            print(f"  FAILED - Sort order broken at {reread_dates[i]} in {label}")
            sys.exit(1)

    dupe_check = set()
    for d in reread_dates:
        if d in dupe_check:
            print(f"  FAILED - Duplicate date {d} in {label}")
            sys.exit(1)
        dupe_check.add(d)

    print(f"  PASSED - {label}.csv is valid ({len(reread_dates)} rows, sorted, no duplicates)")


# ── Phase 5: Final validation report ────────────────────────────────────────

def phase5_report(view_rows, clone_rows):
    print("\n" + "=" * 60)
    print("PHASE 5: Final validation report")
    print("=" * 60)

    total_views = sum(r[1] for r in view_rows)
    total_clones = sum(r[1] for r in clone_rows)

    print(f"  Date range filled: {GAP_START} to {GAP_END}")
    print(f"  Days filled: {len(view_rows)}")
    print(f"  Total views inserted: {total_views}")
    print(f"  Total clones inserted: {total_clones}")

    views_data = read_existing_csv(VIEWS_CSV)
    clones_data = read_existing_csv(CLONES_CSV)

    print(f"\n  views.csv final row count: {len(views_data)}")
    print(f"  clones.csv final row count: {len(clones_data)}")

    print("\n  Checking for remaining gaps > 2 days...")
    views_dates = sorted(views_data.keys())
    gaps_found = 0
    for i in range(1, len(views_dates)):
        gap = (views_dates[i] - views_dates[i - 1]).days
        if gap > 2:
            print(f"    Gap: {views_dates[i-1]} to {views_dates[i]} ({gap} days)")
            gaps_found += 1

    if gaps_found == 0:
        print("    No gaps > 2 days found.")
    else:
        print(f"    {gaps_found} gap(s) found (Oct 20-30 is expected).")

    print("\n  SUCCESS - All phases completed.")


# ── Main ─────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="Fill traffic data gaps from raw event log")
    parser.add_argument("raw_log", type=Path, help="Path to the raw event log CSV")
    args = parser.parse_args()

    if not args.raw_log.exists():
        print(f"Error: File not found: {args.raw_log}")
        sys.exit(1)

    daily_views, daily_clones = phase1_aggregate(args.raw_log)
    phase1_validate(daily_views, daily_clones)

    view_rows, clone_rows = phase2_generate(daily_views, daily_clones)

    phase3_merge(view_rows, clone_rows)

    phase5_report(view_rows, clone_rows)


if __name__ == "__main__":
    main()
