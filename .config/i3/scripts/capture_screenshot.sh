#!/bin/bash

# Folder where screenshots will be saved
folder=~/Pictures/Screenshots
mkdir -p $folder

# Get the current timestamp for unique filenames
timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
year=$(date +"%Y")
month=$(date +"%m")

# Create subfolders for year and month
subfolder="$folder/$year/$month"
mkdir -p $subfolder

# Capture the screenshot
if [[ "$1" == "region" ]]; then
	filename="screenshot_${timestamp}_region.png"
	import "$subfolder/$filename"
else
	filename="screenshot_${timestamp}_full.png"
	import -window root "$subfolder/$filename"
fi

# Copy the filename to greenclip (clipboard manager)
echo "$filename" | greenclip add

# Optional: Show a notification with the screenshot image and allow interaction
notify-send "Screenshot saved" "Image saved as: $filename" -i "$subfolder/$filename" -t 5000
