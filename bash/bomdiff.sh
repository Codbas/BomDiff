#!/bin/bash

set -euo pipefail

BOM_1="$1"
BOM_2="$2"
BOM_DIFF="diff.csv"

# Get column index by header name
get_column_index() {
    local file="$1"
    shift
    local headers=("$@")

    local IFS=','
    read -r header < "$file"
    local i=1
    for col in $header; do
        for name in "${headers[@]}"; do
            if [[ "$col" == "$name" ]]; then
                echo "$i"
                return
            fi
        done
        ((i++))
    done
    echo "-1"
}

# Define header name variants
item_names=("Item" "Component Name")
qty_names=("BOM Quantity" "BoM Quantity per Assembly")
desc_names=("Description")
units_names=("Units")
level_names=("Level")

# Column indexes
item1=$(get_column_index "$BOM_1" "${item_names[@]}")
qty1=$(get_column_index "$BOM_1" "${qty_names[@]}")
desc1=$(get_column_index "$BOM_1" "${desc_names[@]}")
units1=$(get_column_index "$BOM_1" "${units_names[@]}")
level1=$(get_column_index "$BOM_1" "${level_names[@]}")

item2=$(get_column_index "$BOM_2" "${item_names[@]}")
qty2=$(get_column_index "$BOM_2" "${qty_names[@]}")
desc2=$(get_column_index "$BOM_2" "${desc_names[@]}")
units2=$(get_column_index "$BOM_2" "${units_names[@]}")
level2=$(get_column_index "$BOM_2" "${level_names[@]}")

# Ensure required columns exist
if [[ $item1 -eq -1 || $qty1 -eq -1 || $item2 -eq -1 || $qty2 -eq -1 ]]; then
    echo "❌ Missing required Item or Quantity column(s)." >&2
    exit 1
fi

# Output header
has_desc=$(( desc1 != -1 || desc2 != -1 ? 1 : 0 ))
has_level=$(( level1 != -1 || level2 != -1 ? 1 : 0 ))

header="Item"
[[ $has_level -eq 1 ]] && header+=",Level"
[[ $has_desc -eq 1 ]] && header+=",Description"
header+=",Quantity Delta,Units,Action"
echo "$header" > "$BOM_DIFF"

# Main comparison
gawk -v FPAT='([^,]*|"([^"]|"")*")' -v OFS=',' \
    -v item1="$item1" -v qty1="$qty1" -v desc1="$desc1" -v units1="$units1" -v level1="$level1" \
    -v item2="$item2" -v qty2="$qty2" -v desc2="$desc2" -v units2="$units2" -v level2="$level2" \
    -v has_desc="$has_desc" -v has_level="$has_level" '
NR==FNR {
    if (FNR == 1) next
    gsub(/^"|"$/, "", $item1)
    key = $item1
    old_qty[key]   = $qty1 + 0
    old_desc[key]  = (desc1 != -1 ? $desc1 : "")
    old_units[key] = (units1 != -1 ? $units1 : "")
    old_level[key] = (level1 != -1 ? $level1 : "")
    next
}
FNR==1 { next }
{
    gsub(/^"|"$/, "", $item2)
    key = $item2
    qty = $qty2 + 0
    desc = (desc2 != -1 ? $desc2 : "")
    units = (units2 != -1 ? $units2 : "")
    level = (level2 != -1 ? $level2 : "")

    if (!(key in old_qty)) {
        action = "ADDED"
        delta = qty
    } else if (qty != old_qty[key]) {
        delta = qty - old_qty[key]
        action = (delta > 0 ? "INCREASED" : "REDUCED")
        if (desc == "") desc = old_desc[key]
        if (units == "") units = old_units[key]
        if (level == "") level = old_level[key]
    } else {
        seen[key] = 1
        next
    }

    seen[key] = 1

    output = key
    if (has_level) output = output OFS level
    if (has_desc) output = output OFS desc
    output = output OFS delta OFS units OFS action
    print output
}
END {
    for (key in old_qty) {
        if (!(key in seen)) {
            action = "REMOVED"
            delta = -old_qty[key]
            output = key
            if (has_level) output = output OFS old_level[key]
            if (has_desc) output = output OFS old_desc[key]
            output = output OFS delta OFS old_units[key] OFS action
            print output
        }
    }
}' "$BOM_1" "$BOM_2" >> "$BOM_DIFF"

echo "✅ Differences written to $BOM_DIFF"
