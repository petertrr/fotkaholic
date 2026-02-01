#!/usr/bin/env bash
set -euo pipefail

# Script to generate image variants (resize to 600x600)
# Usage: ./scripts/generate-variants.sh image1.jpg image2.jpg ...

# Configuration
RESIZE_WIDTH=1920
RESIZE_HEIGHT=1080

if ! command -v magick &> /dev/null; then
    echo "Error: ImageMagick (magick) is not installed" >&2
    exit 1
fi

# Check if at least one image path is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 image1.jpg image2.jpg ..." >&2
    exit 1
fi

echo "Generating image variants..."
processed_count=0
failed_count=0

for image_path in "$@"; do
    if [ ! -f "$image_path" ]; then
        echo "Warning: File not found: $image_path" >&2
        ((failed_count++))
        continue
    fi

    dir=$(dirname "$image_path")
    filename=$(basename "$image_path")
    filename_no_ext="${filename%.*}"
    file_ext="${filename##*.}"

    # Create resized filename (e.g., photo.jpg -> photo-600x600.jpg)
    resized_filename="${filename_no_ext}-${RESIZE_WIDTH}x${RESIZE_HEIGHT}.${file_ext}"
    resized_path="${dir}/${resized_filename}"

    echo "Processing: $image_path"

    # Resize image using ImageMagick
    # -resize 600x600: resize to fit within 600x600
    # -gravity center: center the image
    if magick "$image_path" \
        -resize "${RESIZE_WIDTH}x${RESIZE_HEIGHT}" \
        -gravity center \
        "$resized_path"; then
        echo "  ✓ Generated: $resized_filename"
        ((processed_count++))
    else
        echo "  ✗ Failed to resize: $image_path" >&2
        ((failed_count++))
    fi
done

echo ""
echo "=== Summary ==="
echo "Successfully generated: $processed_count"
echo "Failed: $failed_count"

if [ $failed_count -gt 0 ]; then
    exit 1
fi
