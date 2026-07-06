#!/bin/bash

input="$1"

if [[ "$input" =~ ^gs://([^/]+)/(.+)$ ]]; then
    bucket="${BASH_REMATCH[1]}"
    path="${BASH_REMATCH[2]}"
    echo "https://console.cloud.google.com/storage/browser/${bucket}/${path}"
else
    echo "Invalid gs:// path"
    exit 1
fi

