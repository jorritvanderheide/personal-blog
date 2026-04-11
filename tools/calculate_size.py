#!/usr/bin/env python3
"""
Post-build script that measures total HTML content size and injects it
into the site capacity meter. Also enforces page budget.

Run after hugo build:
    python3 tools/calculate_size.py --directory public/
"""

import argparse
import re
import sys
from pathlib import Path

PAGE_BUDGET_KB = 16
SITE_CAPACITY_KB = 1024


def calculate(public_dir):
    public = Path(public_dir)
    html_files = list(public.rglob("*.html"))

    total_bytes = 0
    violations = []

    for path in html_files:
        size = path.stat().st_size
        total_bytes += size
        size_kb = size // 1024

        if size_kb > PAGE_BUDGET_KB:
            violations.append(f"  {path.relative_to(public)}: {size_kb}KB")

    total_kb = total_bytes // 1024

    # Inject site total into HTML placeholders
    for path in html_files:
        content = path.read_text(encoding="utf-8")
        for pattern in [
            r'<span class=["\']?site-size["\']?>[^<]*</span>',
        ]:
            if re.search(pattern, content):
                content = re.sub(pattern, f"{total_kb}KB", content)
                path.write_text(content, encoding="utf-8")

    return total_kb, violations


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--directory", default="public/")
    args = parser.parse_args()

    public = Path(args.directory)
    if not public.exists():
        print(f"Not found: {public}")
        sys.exit(1)

    total_kb, violations = calculate(args.directory)
    print(f"Site: {total_kb}KB / {SITE_CAPACITY_KB}KB (HTML only)")

    if violations:
        print(f"\nPage budget exceeded ({PAGE_BUDGET_KB}KB):")
        for v in violations:
            print(v)
        sys.exit(1)

    if total_kb > SITE_CAPACITY_KB:
        print(f"\nSite capacity exceeded: {total_kb}KB / {SITE_CAPACITY_KB}KB")
        sys.exit(1)

    print("OK")
