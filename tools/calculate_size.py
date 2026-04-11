#!/usr/bin/env python3
"""
Post-build script that measures actual page sizes and injects them into
the rendered HTML. Also calculates total site size for the capacity meter.

Run after hugo build:
    python3 tools/calculate_size.py --directory public/

Replaces:
    <span class="page-size"></span>  → actual page size in KB
    <span class="site-size"></span>  → total site size in KB
"""

import argparse
import os
from pathlib import Path


def get_file_size(path):
    """Return file size in bytes."""
    return os.path.getsize(path)


def get_page_size(html_path, public_dir):
    """Calculate total size of an HTML page including its linked CSS."""
    size = get_file_size(html_path)

    # Add shared CSS (counted once per page as it's what the browser loads)
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
    """Walk all HTML files and inject page/site sizes."""
    public_path = Path(public_dir)
    site_size_kb = get_site_size(public_path) // 1024

    html_files = list(public_path.rglob("*.html"))

    for html_path in html_files:
        content = html_path.read_text(encoding="utf-8")
        changed = False

        # Handle both quoted and unquoted class attributes (Hugo minifier)
        for page_placeholder in ['<span class="page-size"></span>', '<span class=page-size></span>']:
            if page_placeholder in content:
                page_kb = get_page_size(html_path, public_path) // 1024
                content = content.replace(page_placeholder, f'{page_kb}KB')
                changed = True

        for site_placeholder in ['<span class="site-size"></span>', '<span class=site-size></span>']:
            if site_placeholder in content:
                content = content.replace(site_placeholder, f'{site_size_kb}KB')
                changed = True
            changed = True

        if changed:
            html_path.write_text(content, encoding="utf-8")
            print(f"  {html_path.relative_to(public_path)}: {get_page_size(html_path, public_path) // 1024}KB")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Calculate and inject page sizes")
    parser.add_argument("--directory", default="public/", help="Hugo output directory")
    args = parser.parse_args()

    public = Path(args.directory)
    if not public.exists():
        print(f"Directory not found: {public}")
        exit(1)

    print(f"Site total: {get_site_size(public) // 1024}KB")
    inject_sizes(public)
    print("Done.")
