#!/usr/bin/env -S uv run --quiet --script
# /// script
# dependencies = ["hijri-converter"]
# ///

from hijri_converter import Gregorian
from datetime import date
import subprocess

def shape_text(text):
    """
    Pass text through fribidi to reshape/reorder for terminal display.
    --nopad: Don't add padding spaces.
    --nobreak: Don't break lines.
    """
    try:
        result = subprocess.run(
            ['fribidi', '--nopad', '--nobreak'],
            input=text,
            text=True,
            capture_output=True,
            check=True
        )
        return result.stdout.strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return text

def to_arabic_nums(text):
    western = "0123456789"
    eastern = "٠١٢٣٤٥٦٧٨٩"
    table = str.maketrans(western, eastern)
    return text.translate(table)

hijri = Gregorian.today().to_hijri()

# Construct the full string
full_date = f"{hijri.day} {hijri.month_name('ar')} {hijri.year} هـ"
full_date_arabic = to_arabic_nums(full_date)

# Shape it for display
print(shape_text(full_date_arabic))
