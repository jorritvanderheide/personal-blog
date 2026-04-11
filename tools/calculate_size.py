#!/usr/bin/env python3
"""
Post-build script that measures actual page sizes and injects them into
the rendered HTML. Also checks page budget and site capacity.

Run after hugo build:
    python3 tools/calculate_size.py --directory public/

Replaces Hugo estimates with real measured bytes:
    <span class="page-size">~2KB</span>  → 17KB
    <span class="site-size">~27KB</span> → 123KB
"""

import argparse
import os
import re
import sys
from pathlib import Path

PAGE_BUDGET_KB = 24
SITE_CAPACITY_KB = 1024


def get_file_size(path):
    """Return file size in bytes."""
    return os.path.getsize(path)


def get_page_size(html_path, public_dir):
    """Calculate total size of an HTML page including its linked CSS."""
    size = get_file_size(html_path)

    css_dir = public_dir / "css"
    if css_dir.exists():
        for css_file in css_dir.glob("*.css"):
            size += get_file_size(css_file)

    return size


def get_site_size(public_dir):
    """Calculate total size of all files in public/."""
    total = 0
    for path in public_dir.rglob("*"):
        if path.is_file():
            total += get_file_size(path)
    return total


def inject_sizes(public_dir):
    """Walk all HTML files, inject sizes, and enforce budgets."""
    public_path = Path(public_dir)
    site_size_kb = get_site_size(public_path) // 1024
    violations = []

    html_files = list(public_path.rglob("*.html"))

    for html_path in html_files:
        content = html_path.read_text(encoding="utf-8")
        changed = False
        page_kb = get_page_size(html_path, public_path) // 1024

        # Replace page-size span (may contain Hugo estimate like ~2KB)
        page_pattern = r'<span class=["\']?page-size["\']?>[^<]*</span>'
        if re.search(page_pattern, content):
            content = re.sub(page_pattern, f'{page_kb}KB', content)
            changed = True

        # Replace site-size span (may contain Hugo estimate like ~27KB)
        site_pattern = r'<span class=["\']?site-size["\']?>[^<]*</span>'
        if re.search(site_pattern, content):
            content = re.sub(site_pattern, f'{site_size_kb}KB', content)
            changed = True

        if changed:
            html_path.write_text(content, encoding="utf-8")
            rel = html_path.relative_to(public_path)
            print(f"  {rel}: {page_kb}KB")

        # Check page budget
        if page_kb > PAGE_BUDGET_KB:
            rel = html_path.relative_to(public_path)
            violations.append(f"  {rel}: {page_kb}KB (budget: {PAGE_BUDGET_KB}KB)")

    return violations, site_size_kb


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Calculate and inject page sizes")
    parser.add_argument("--directory", default="public/", help="Hugo output directory")
    args = parser.parse_args()

    public = Path(args.directory)
    if not public.exists():
        print(f"Directory not found: {public}")
        sys.exit(1)

    site_kb = get_site_size(public) // 1024
    print(f"Site total: {site_kb}KB / {SITE_CAPACITY_KB}KB")

    violations, _ = inject_sizes(public)

    if violations:
        print(f"\nPage budget exceeded ({PAGE_BUDGET_KB}KB):")
        for v in violations:
            print(v)
        sys.exit(1)

    if site_kb > SITE_CAPACITY_KB:
        print(f"\nSite capacity exceeded: {site_kb}KB / {SITE_CAPACITY_KB}KB")
        sys.exit(1)

    print("Done.")
