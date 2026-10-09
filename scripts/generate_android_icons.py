#!/usr/bin/env python3
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright (C) 2026 FoxSecura contributors.
"""Rasterise the FoxSecura vector into Android launcher mipmaps.

Requires cairosvg: python3 -m pip install cairosvg
Run AFTER flutter create. No Android permissions or signing material involved.
"""
from pathlib import Path
import cairosvg

root = Path(__file__).resolve().parents[1]
source = root / "assets" / "branding" / "foxsecura-logo.svg"
android = root / "android" / "app" / "src" / "main" / "res"
sizes = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
for density, size in sizes.items():
    target = android / f"mipmap-{density}" / "ic_launcher.png"
    target.parent.mkdir(parents=True, exist_ok=True)
    cairosvg.svg2png(url=str(source), write_to=str(target), output_width=size, output_height=size)
    print(f"Generated {target.relative_to(root)} ({size}x{size})")
