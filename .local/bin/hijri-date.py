#!/usr/bin/env -S uv run --quiet --script
# /// script
# dependencies = ["hijri-converter"]
# ///

from hijri_converter import Gregorian
from datetime import date

hijri = Gregorian.today().to_hijri()
print(f"{hijri.day} {hijri.month_name('ar')} {hijri.year}هـ")
