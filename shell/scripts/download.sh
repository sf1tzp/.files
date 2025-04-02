#!/usr/bin/env bash

## Simple download wrapper around curl
## Download default location ~/Downloads
## Ask to Overwrite
function download() {
    local url="$1"
    local output_path="$2"

    # Check if URL is provided
    if [[ -z "$url" ]]; then
        echo "Error: No URL provided."
        echo "Usage: download <URL> [output_path]"
        return 1
    fi

    # If no output path is provided, use default location and extract filename from URL
    if [[ -z "$output_path" ]]; then
        local filename
        filename=$(basename "$url" | sed 's/\?.*//') # Remove query parameters
        output_path="$HOME/Downloads/$filename"
    fi

    # Ensure the download directory exists
    mkdir -p "$(dirname "$output_path")"

    # Check if file already exists
    if [[ -f "$output_path" ]]; then
        read -r -p "File '$output_path' already exists. Overwrite? (y/n): " overwrite
        if [[ "$overwrite" != "y" && "$overwrite" != "Y" ]]; then
            echo "Download canceled."
            return 0
        fi
    fi

    # Perform the download with curl
    echo "Downloading $url to $output_path..."
    curl --location --progress-bar --output "$output_path" "$url"

    # Check if download was successful
    if [[ $? -eq 0 ]]; then
        local filesize
        filesize=$(stat --format="%s" "$output_path" 2>/dev/null || stat -f"%z" "$output_path")

        # Convert filesize to human-readable format
        if [[ "$filesize" -ge 1073741824 ]]; then
            filesize_human=$(echo "scale=2; $filesize/1073741824" | bc)gB
        elif [[ "$filesize" -ge 1048576 ]]; then
            filesize_human=$(echo "scale=2; $filesize/1048576" | bc)mB
        elif [[ "$filesize" -ge 1024 ]]; then
            filesize_human=$(echo "scale=2; $filesize/1024" | bc)kB
        else
            filesize_human="${filesize}B"
        fi

        echo "Download completed successfully ($filesize_human): $output_path"
        return 0
    else
        echo "Error: Download failed."
        return 1
    fi
}
