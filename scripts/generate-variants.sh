#!/usr/bin/env bash
set -euo pipefail

# Script to generate image variants (resize to RESIZE_WIDTH*RESIZE_HEIGHT)
# Usage: ./scripts/generate-variants.sh image1.jpg image2.jpg ...

# Configuration
export RESIZE_WIDTH=1920
export RESIZE_HEIGHT=1080

if ! command -v magick &> /dev/null; then
    echo "Error: ImageMagick (magick) is not installed" >&2
    exit 1
fi

if ! command -v exiftool &> /dev/null; then
    echo "Error: exiftool is not installed" >&2
    exit 1
fi

# Check if at least one image path is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 image1.jpg image2.jpg ..." >&2
    exit 1
fi

echo "Generating image variants..."
export processed_count=0
export failed_count=0

process_image() {
    image_path=$1
    if [ ! -f "$image_path" ]; then
        echo "Warning: File not found: $image_path" >&2
        ((failed_count++))
        continue
    fi

    dir=$(dirname "$image_path")
    filename=$(basename "$image_path")
    file_ext="${filename##*.}"

    # Extract EXIF timestamp from image
    exif_date=$(exiftool -s3 -DateTimeOriginal "$image_path" 2>/dev/null)
    if [ -z "$exif_date" ]; then
        # Fall back to CreateDate if DateTimeOriginal is not available
        exif_date=$(exiftool -s3 -CreateDate "$image_path" 2>/dev/null)
    fi

    if [ -z "$exif_date" ]; then
        echo "  ⚠ Warning: No EXIF date found, using current time" >&2
        base_timestamp=$(date +"%Y%m%d_%H%M%S")
    else
        # Convert EXIF date format (YYYY:MM:DD HH:MM:SS) to compact format (remove colons and spaces)
        compact_timestamp=$(echo "$exif_date" | sed 's/[: ]//g' | cut -c1-14)
        # Add underscore between date and time: YYYYMMDD_HHMMSS
        base_timestamp="${compact_timestamp:0:8}_${compact_timestamp:8:6}"
    fi

    # If needed, adjust timestamp
    timestamp="$base_timestamp"

    file_hash=$(md5sum "$image_path" | cut -c1-8)
    unique_filename="${timestamp}_${file_hash}.${file_ext}"
    unique_path="${dir}/${unique_filename}"

    echo "Processing: $image_path"

    # Rename base file to unique filename
    if mv "$image_path" "$unique_path"; then
        echo "  ✓ Renamed to: $unique_filename"
    else
        echo "  ✗ Failed to rename: $image_path" >&2
        failed_count=$((failed_count+1))
        continue
    fi

    # Strip EXIF data from base file, keeping only Artist, Creator, and DateTimeCreated
    if exiftool -all= -tagsfromfile @ -Artist -Creator -DateTimeOriginal -DateTimeCreated -CreateDate -overwrite_original "$unique_path" 2>/dev/null; then
        echo "  ✓ Stripped EXIF data from base file"
    else
        echo "  ⚠ Warning: Failed to strip EXIF data from: $unique_path" >&2
    fi

    # Create resized filename (e.g., 20260323_143022_a1b2c3d4.jpg -> 20260323_143022_a1b2c3d4-1920x1080.jpg)
    filename_no_ext="${unique_filename%.*}"
    resized_filename="${filename_no_ext}-${RESIZE_WIDTH}x${RESIZE_HEIGHT}.${file_ext}"
    resized_path="${dir}/${resized_filename}"

    # Resize image using ImageMagick
    # -resize 1920x1080: resize to fit within dimensions
    # -gravity center: center the image
    if magick "$unique_path" \
        -resize "${RESIZE_WIDTH}x${RESIZE_HEIGHT}" \
        -gravity center \
        "$resized_path"; then
        echo "  ✓ Generated variant: $resized_filename"

        # Strip EXIF data from variant, keeping only Artist, Creator, and DateTimeCreated
        if exiftool -all= -tagsfromfile @ -Artist -Creator -DateTimeOriginal -DateTimeCreated -CreateDate -overwrite_original "$resized_path" 2>/dev/null; then
            echo "  ✓ Stripped EXIF data from variant"
        else
            echo "  ⚠ Warning: Failed to strip EXIF data from: $resized_path" >&2
        fi

        processed_count=$((processed_count+1))
    else
        echo "  ✗ Failed to resize: $unique_path" >&2
        failed_count=$((failed_count+1))
    fi
}
export -f process_image

parallel process_image {} ::: "$@"

echo ""
echo "=== Summary ==="
echo "Successfully generated: $processed_count"
echo "Failed: $failed_count"

if [ $failed_count -gt 0 ]; then
    exit 1
fi
