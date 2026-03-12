#!/usr/bin/env python3
import subprocess
from datetime import datetime

def shape_text(text):
    """
    Since Kitty handles RTL but tmux status bar might need a hint, 
    we reverse the text manually so that when it's rendered, it appears correctly.
    """
    return text[::-1]

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
