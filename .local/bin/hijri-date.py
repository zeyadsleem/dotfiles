#!/usr/bin/env -S uv run --quiet --script
# /// script
# dependencies = ["hijri-converter"]
# ///

from hijri_converter import Gregorian
from datetime import date
import subprocess

def shape_text(text):
    """
    Since Kitty handles RTL but tmux status bar might need a hint, 
    we reverse the text manually so that when it's rendered, it appears correctly.
    """
    return text[::-1]

def to_arabic_nums(text):
    western = "0123456789"
    eastern = "٠١٢٣٤٥٦٧٨٩"
    table = str.maketrans(western, eastern)
    return text.translate(table)

hijri = Gregorian.today().to_hijri()

# Construct the full string in English
full_date = f"{hijri.day} {hijri.month_name('en')} {hijri.year} AH"

# Shape text is now a passthrough since we are using English
print(full_date)
