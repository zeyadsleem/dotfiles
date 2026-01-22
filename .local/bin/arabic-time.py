#!/usr/bin/env python3
import subprocess
from datetime import datetime

def shape_text(text):
    """
    Pass text through fribidi to reshape/reorder for terminal display.
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

# Mapping for standard digits to Eastern Arabic numerals
trans_table = str.maketrans("0123456789", "٠١٢٣٤٥٦٧٨٩")

now = datetime.now()

# Format time HH:MM
time_str = now.strftime("%I:%M")
# Translate digits to Arabic
arabic_time = time_str.translate(trans_table)

# Translate period
period = now.strftime("%p")
if period == "AM":
    arabic_period = "صباحاً"
else:
    arabic_period = "مساءً"

# Combine
full_text = f"{arabic_time} {arabic_period}"

# Print shaped text
print(shape_text(full_text))
