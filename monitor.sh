#!/bin/bash

HISTORY_DIR="$HOME/.clipboard-history"
HISTORY_FILE="$HISTORY_DIR/history.txt"
TMP_FILE="$HISTORY_DIR/.history.tmp"
MAX_ENTRIES=10
SEPARATOR="===CLIP==="

mkdir -p "$HISTORY_DIR"
touch "$HISTORY_FILE"

trap 'rm -f "$TMP_FILE"' EXIT INT TERM

last_hash=""
entry_count=0

if [ -s "$HISTORY_FILE" ]; then
    entry_count=$(grep -c "^${SEPARATOR}$" "$HISTORY_FILE")
fi

while true; do
    current=$(pbpaste 2>/dev/null)

    if [ -n "$current" ]; then
        current_hash=$(printf '%s' "$current" | md5 -q)

        if [ "$current_hash" != "$last_hash" ]; then
            last_hash="$current_hash"

            {
                printf '%s\n' "$SEPARATOR"
                printf '%s\n' "$current"
                cat "$HISTORY_FILE"
            } > "$TMP_FILE"
            mv "$TMP_FILE" "$HISTORY_FILE"

            entry_count=$((entry_count + 1))

            if [ "$entry_count" -gt "$MAX_ENTRIES" ]; then
                awk -v sep="$SEPARATOR" -v max="$MAX_ENTRIES" '
                    BEGIN { count = 0 }
                    $0 == sep { count++ }
                    count <= max { print }
                ' "$HISTORY_FILE" > "$TMP_FILE"
                mv "$TMP_FILE" "$HISTORY_FILE"
                entry_count=$MAX_ENTRIES
            fi
        fi
    fi

    sleep 1
done
