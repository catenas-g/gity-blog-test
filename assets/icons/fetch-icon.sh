#!/bin/sh
# Usage: fetch-icon.sh <icon-name> <icon-type>

set -e -u

tablericon_url="https://raw.githubusercontent.com/tabler/tabler-icons/refs/heads/main/icons/%TYPE%/%NAME%.svg"

# Check if both arguments are provided
if [ $# -lt 1 ] || [ $# -gt 2 ]; then
    echo "Error: One or two arguments required" >&2
    echo "Usage: $0 <icon-name> [icon-type]" >&2
    exit 1
fi

# Store arguments in variables
icon_name="${1-""}"
icon_type="${2-"outline"}"

# Check if icon type is valid
case $icon_type in
"outline" | "filled") ;;
*)
    echo "Error: Invalid icon type: $icon_type" >&2
    echo "Valid types: outline, filled" >&2
    exit 1
    ;;
esac

# Fetch the icon
if ! curl -sf "$(echo "$tablericon_url" | sed "s/%TYPE%/$icon_type/g;s/%NAME%/$icon_name/g")" -o "$(dirname "$0")/$icon_name.svg"; then
    echo "Error: Failed to download the icon" >&2
    exit 1
fi
