#!/bin/bash

HISTORY_DIR="$HOME/.clipboard-history"
HISTORY_FILE="$HISTORY_DIR/history.txt"
SEPARATOR="===CLIP==="
ITEMS_FILE="/tmp/clipboard-picker-items.txt"
RESULT_FILE="/tmp/clipboard-picker-result.txt"
PICKER_APP="/tmp/ClipboardPicker.app"

load_items() {
    items=()
    full_items=()
    index=0
    current_item=""

    [ ! -s "$HISTORY_FILE" ] && return

    while IFS= read -r line; do
        if [ "$line" = "$SEPARATOR" ]; then
            if [ -n "$current_item" ]; then
                full_items+=("$current_item")
                preview=$(printf '%s' "$current_item" | head -1 | LC_ALL=C cut -c1-80)
                if [ ${#preview} -ge 80 ] || [ "$(printf '%s' "$current_item" | wc -l)" -gt 1 ]; then
                    preview="${preview}..."
                fi
                index=$((index + 1))
                items+=("${index}. ${preview}")
            fi
            current_item=""
        else
            if [ -z "$current_item" ]; then
                current_item="$line"
            else
                current_item="${current_item}
${line}"
            fi
        fi
    done < "$HISTORY_FILE"

    if [ -n "$current_item" ]; then
        full_items+=("$current_item")
        preview=$(printf '%s' "$current_item" | head -1 | LC_ALL=C cut -c1-80)
        if [ ${#preview} -ge 80 ] || [ "$(printf '%s' "$current_item" | wc -l)" -gt 1 ]; then
            preview="${preview}..."
        fi
        index=$((index + 1))
        items+=("${index}. ${preview}")
    fi
}

save_items() {
    local tmp_save="$HISTORY_DIR/.history.tmp"
    > "$tmp_save"
    for item in "${full_items[@]}"; do
        printf '%s\n' "$SEPARATOR" >> "$tmp_save"
        printf '%s\n' "$item" >> "$tmp_save"
    done
    mv "$tmp_save" "$HISTORY_FILE"
}

compile_picker_app() {
    [ -d "$PICKER_APP" ] && return
    osacompile -o "$PICKER_APP" "$HISTORY_DIR/picker.applescript"
}

show_picker() {
    local mode="$1"
    rm -f "$RESULT_FILE"

    {
        echo "$mode"
        for item in "${items[@]}"; do
            echo "$item"
        done
    } > "$ITEMS_FILE"

    open -W "$PICKER_APP"

    if [ -f "$RESULT_FILE" ]; then
        tr -d '\n' < "$RESULT_FILE"
    else
        echo "CANCEL"
    fi
}

compile_picker_app

while true; do
    load_items

    if [ ${#items[@]} -eq 0 ]; then
        osascript -e 'tell me to activate' -e 'display dialog "Historico de clipboard vazio." with title "Clipboard History" buttons {"OK"} default button "OK" with icon note'
        exit 0
    fi

    items+=("--- Excluir um item ---")

    result=$(show_picker "paste")

    if [ "$result" = "CANCEL" ] || [ -z "$result" ]; then
        exit 0
    fi

    if [ "$result" = "--- Excluir um item ---" ]; then
        while true; do
            load_items
            items+=("--- Voltar ---")

            result=$(show_picker "delete")

            if [ "$result" = "CANCEL" ] || [ -z "$result" ] || [ "$result" = "--- Voltar ---" ]; then
                break
            fi

            selected_index=$(printf '%s' "$result" | sed 's/^\([0-9]*\)\..*/\1/')
            if [ -n "$selected_index" ] && [ "$selected_index" -ge 1 ] 2>/dev/null; then
                array_index=$((selected_index - 1))
                if [ "$array_index" -lt "${#full_items[@]}" ]; then
                    unset 'full_items[$array_index]'
                    full_items=("${full_items[@]}")
                    save_items
                fi
            fi
        done
        continue
    fi

    selected_index=$(printf '%s' "$result" | sed 's/^\([0-9]*\)\..*/\1/')

    if [ -n "$selected_index" ] && [ "$selected_index" -ge 1 ] 2>/dev/null; then
        array_index=$((selected_index - 1))
        load_items
        if [ "$array_index" -lt "${#full_items[@]}" ]; then
            printf '%s' "${full_items[$array_index]}" | pbcopy
            touch "$HISTORY_DIR/.do_paste"
        fi
    fi
    exit 0
done
