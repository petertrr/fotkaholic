#!/usr/bin/env bash
set -euo pipefail

# Script to upload images to Cloudflare R2
# Usage: ./scripts/upload-images.sh image1.jpg image1-600x600.jpg image2.jpg image2-600x600.jpg ...

# Configuration
if [ -z "${CF_ACCOUNT_ID:-}" ]; then
    echo "Error: CF_ACCOUNT_ID environment variable is required" >&2
    exit 1
fi
R2_BUCKET="${R2_BUCKET:-fotkaholic-site-assets}"
R2_ENDPOINT="https://${CF_ACCOUNT_ID}.r2.cloudflarestorage.com"
R2_FOLDER="${R2_FOLDER:-main}"

# Check if aws CLI is installed
if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI is not installed" >&2
    exit 1
fi

# Check if at least one image path is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 image1.jpg image2.jpg ..." >&2
    exit 1
fi

# Check for required environment variables
if [ -z "${R2_ACCESS_KEY_ID:-}" ] || [ -z "${R2_SECRET_ACCESS_KEY:-}" ]; then
    echo "Error: R2_ACCESS_KEY_ID and R2_SECRET_ACCESS_KEY environment variables are required" >&2
    exit 1
fi

# Configure AWS CLI for R2
export AWS_ACCESS_KEY_ID="$R2_ACCESS_KEY_ID"
export AWS_SECRET_ACCESS_KEY="$R2_SECRET_ACCESS_KEY"

echo "Uploading images to R2..."
uploaded_count=0
failed_count=0

for image_path in "$@"; do
    # Check if file exists
    if [ ! -f "$image_path" ]; then
        echo "Warning: File not found: $image_path" >&2
        failed_count=$((failed_count+1))
        continue
    fi

    # Get filename
    filename=$(basename "$image_path")

    echo "Uploading: $filename"

    # Upload image to R2
    if aws s3 cp "$image_path" \
        "s3://${R2_BUCKET}/${R2_FOLDER}/${filename}" \
        --endpoint-url="$R2_ENDPOINT" \
        --no-progress; then
        echo "  ✓ Uploaded: $filename"
        uploaded_count=$((uploaded_count+1))
    else
        echo "  ✗ Failed to upload: $filename" >&2
        failed_count=$((failed_count+1))
    fi
done

echo ""
echo "=== Summary ==="
echo "Successfully uploaded: $uploaded_count"
echo "Failed: $failed_count"

if [ $failed_count -gt 0 ]; then
    exit 1
fi
