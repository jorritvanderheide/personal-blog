#!/usr/bin/env python3

import os
from PIL import Image
import hitherdither

CONTENT_DIR = "./content"
IMAGE_EXT = (".jpg", ".jpeg", ".png", ".webp")

PALETTE = hitherdither.palette.Palette([
    (25,25,25), (75,75,75), (125,125,125),
    (175,175,175), (225,225,225), (250,250,250)
])

def dither_image(source, dest):
    try:
        img = Image.open(source).convert("RGB")
        img.thumbnail((800, 800), Image.LANCZOS)
        img_dithered = hitherdither.ordered.bayer.bayer_dithering(img, PALETTE, [96,96,96], order=8)
        img_dithered.save(dest, optimize=True)
        print(f"Created dithered image: {dest}")
    except Exception as e:
        print(f"Failed to convert {source}: {e}")

for root, _, files in os.walk(CONTENT_DIR):
    for fname in files:
        if fname.lower().endswith(IMAGE_EXT):
            if ".dithered" in fname:
                continue

            src = os.path.join(root, fname)
            name, _ = os.path.splitext(fname)
            dest = os.path.join(root, f"{name}.dithered.webp")
            if not os.path.exists(dest):
                dither_image(src, dest)
            else:
                print(f"Skipped (already exists): {dest}")