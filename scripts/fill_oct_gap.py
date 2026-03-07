"""
Fill the Oct 20-30 traffic gap and fix Nov 14 partial data using the second raw event log.

Usage:
    python scripts/fill_oct_gap.py <path-to-raw-log.csv>
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

GAP_START = date(2025, 10, 20)
GAP_END = date(2025, 10, 30)

NOV14 = date(2025, 11, 14)

OVERLAP_START = date(2025, 11, 1)
OVERLAP_END = date(2025, 11, 13)


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
    print("\n  Checkpoint 1: Cross-validating Nov 1-13 (API data)...")

    existing_views = read_existing_csv(VIEWS_CSV)
    existing_clones = read_existing_csv(CLONES_CSV)

    TOLERANCE = 1
    warnings = []
    errors = []
    exact = 0

    for d in date_range(OVERLAP_START, OVERLAP_END):
        raw_v = daily_views.get(d, 0)
        csv_v = existing_views.get(d, (0, 0))[0]
        diff_v = abs(raw_v - csv_v)
        if diff_v > TOLERANCE:
            errors.append(f"  Views {d}: raw={raw_v} csv={csv_v} (diff={diff_v})")
        elif diff_v > 0:
            warnings.append(f"  Views {d}: raw={raw_v} csv={csv_v} (diff={diff_v})")
        else:
            exact += 1

    if warnings:
        print("  Warnings (within tolerance):")
        for w in warnings:
            print(f"    {w}")

    if errors:
        print("  FAILED - Mismatches beyond tolerance:")
        for e in errors:
            print(f"    {e}")
        sys.exit(1)

    print(f"  PASSED - {exact} exact matches, {len(warnings)} within tolerance.")


def phase2_generate(daily_views, daily_clones):
    print("\n" + "=" * 60)
    print("PHASE 2: Generate gap rows (Oct 20-30) and fix Nov 14")
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

    nov14_views = daily_views.get(NOV14, 0)
    nov14_clones = daily_clones.get(NOV14, 0)
    old_nov14_views = existing_views.get(NOV14, (0, 0))
    old_nov14_clones = existing_clones.get(NOV14, (0, 0))

    print(f"\n  Nov 14 fix: views {old_nov14_views[0]} -> {nov14_views}, "
          f"clones {old_nov14_clones[0]} -> {nov14_clones}")

    print("\n  Checkpoint 2: Validating...")
    errors = []
    if len(view_rows) != 11:
        errors.append(f"Expected 11 gap rows, got {len(view_rows)}")
    if total_views < 1000 or total_views > 6000:
        errors.append(f"Total views {total_views} outside expected range")
    if nov14_views < 100:
        errors.append(f"Nov 14 views {nov14_views} unexpectedly low")

    if errors:
        print("  FAILED:")
        for e in errors:
            print(f"    {e}")
        sys.exit(1)

    print("  PASSED.")
    return view_rows, clone_rows, nov14_views, nov14_clones


def phase3_merge(view_rows, clone_rows, nov14_views, nov14_clones):
    print("\n" + "=" * 60)
    print("PHASE 3: Merge into CSV files")
    print("=" * 60)

    merge_csv(
        VIEWS_CSV,
        "_date,total_views,unique_views",
        view_rows,
        {NOV14: (nov14_views, 0)},
        "views"
    )

    merge_csv(
        CLONES_CSV,
        "_date,total_clones,unique_clones",
        clone_rows,
        {NOV14: (nov14_clones, 0)},
        "clones"
    )


def merge_csv(path: Path, header: str, new_rows, updates: dict, label: str):
    existing = read_existing_csv(path)
    original_count = len(existing)

    for d, total, unique in new_rows:
        if d in existing:
            print(f"  ABORT - Duplicate {d} in {label}")
            sys.exit(1)
        existing[d] = (total, unique)

    for d, (total, unique) in updates.items():
        old = existing.get(d, (0, 0))
        print(f"  {label} {d}: {old[0]},{old[1]} -> {total},{unique}")
        existing[d] = (total, unique)

    sorted_dates = sorted(existing.keys())

    with open(path, "w", newline="", encoding="utf-8") as f:
        f.write(header + "\n")
        for d in sorted_dates:
            total, unique = existing[d]
            f.write(f"{d},{total},{unique}\n")

    new_count = len(sorted_dates)
    print(f"  {label}.csv: {original_count} -> {new_count} rows (+{new_count - original_count})")

    reread = read_existing_csv(path)
    reread_dates = sorted(reread.keys())

    if reread_dates != sorted_dates:
        print(f"  FAILED - Re-read mismatch for {label}")
        sys.exit(1)

    for i in range(1, len(reread_dates)):
        if reread_dates[i] <= reread_dates[i - 1]:
            print(f"  FAILED - Sort order broken at {reread_dates[i]}")
            sys.exit(1)

    print(f"  PASSED - {label}.csv valid ({len(reread_dates)} rows, sorted, no dupes)")


def phase5_report(view_rows, clone_rows, nov14_views):
    print("\n" + "=" * 60)
    print("PHASE 5: Final validation report")
    print("=" * 60)

    total_views = sum(r[1] for r in view_rows)
    total_clones = sum(r[1] for r in clone_rows)

    print(f"  Oct gap filled: {GAP_START} to {GAP_END} ({len(view_rows)} days)")
    print(f"  Total views inserted: {total_views}")
    print(f"  Total clones inserted: {total_clones}")
    print(f"  Nov 14 views fixed: 2 -> {nov14_views}")

    views_data = read_existing_csv(VIEWS_CSV)
    clones_data = read_existing_csv(CLONES_CSV)

    print(f"\n  views.csv final row count: {len(views_data)}")
    print(f"  clones.csv final row count: {len(clones_data)}")

    print("\n  Checking for remaining gaps > 2 days in views.csv...")
    views_dates = sorted(views_data.keys())
    gaps_found = 0
    for i in range(1, len(views_dates)):
        gap = (views_dates[i] - views_dates[i - 1]).days
        if gap > 2:
            print(f"    Gap: {views_dates[i-1]} to {views_dates[i]} ({gap} days)")
            gaps_found += 1

    if gaps_found == 0:
        print("    No gaps > 2 days found.")

    print("\n  SUCCESS - All phases completed.")


def main():
    parser = argparse.ArgumentParser(description="Fill Oct 20-30 gap and fix Nov 14")
    parser.add_argument("raw_log", type=Path, help="Path to the raw event log CSV")
    args = parser.parse_args()

    if not args.raw_log.exists():
        print(f"Error: File not found: {args.raw_log}")
        sys.exit(1)

    daily_views, daily_clones = phase1_aggregate(args.raw_log)
    phase1_validate(daily_views, daily_clones)

    view_rows, clone_rows, nov14_views, nov14_clones = phase2_generate(daily_views, daily_clones)

    phase3_merge(view_rows, clone_rows, nov14_views, nov14_clones)

    phase5_report(view_rows, clone_rows, nov14_views)


if __name__ == "__main__":
    main()
