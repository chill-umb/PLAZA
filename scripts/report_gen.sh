#!/bin/bash

# Ensure Bash 4+ for associative arrays
if [ "${BASH_VERSINFO:-0}" -lt 4 ]; then
    echo "Error: This script requires Bash 4.0 or higher."
    exit 1
fi

declare -A reset_matrix gc_matrix ops_matrix all_policies all_rows

# --- Phase 1: Data Collection ---

for d_top in rsvz-*/; do
    [[ -d "$d_top" ]] || continue
    d_top=${d_top%/} 
    
    # Extract x and y using hyphenated keys
    x=$(echo "$d_top" | sed -n 's/.*gcstart-\([^_]*\).*/\1/p')
    y=$(echo "$d_top" | sed -n 's/.*gcstop-\([^_]*\).*/\1/p')
    
    row_label="${x}->${y}"
    all_rows["$row_label"]=1

    for d_fp in "$d_top"/fp-*/; do
        [[ -d "$d_fp" ]] || continue
        d_fp=${d_fp%/}
        policy=${d_fp##*/fp-}
        all_policies["$policy"]=1

        LATEST_NAME_LOG=$(ls "$d_fp/${policy}"_*.log 2>/dev/null | sort | tail -n 1)
        LATEST_STDOUT_LOG=$(ls "$d_fp/stdout_"*.log 2>/dev/null | sort | tail -n 1)

        # Extraction - Reset and GC
        if [[ -f "$LATEST_NAME_LOG" ]]; then
            val_reset=$(grep "Reset count =" "$LATEST_NAME_LOG" | tail -n 1 | sed -n 's/.*Reset count = \([0-9]*\).*/\1/p')
            reset_matrix["$row_label,$policy"]=$val_reset

            gc_mb=$(grep "Total movement due to GC =" "$LATEST_NAME_LOG" | tail -n 1 | sed -n 's/.*Total movement due to GC = \([0-9.]*\).*/\1/p')
            val_gc=$(awk -v mb="$gc_mb" 'BEGIN { if (mb == "" || mb == "0") print "0.00"; else printf "%.2f", mb / 1024 }')
            gc_matrix["$row_label,$policy"]=$val_gc
        fi

        # Extraction - Ops
        if [[ -f "$LATEST_STDOUT_LOG" ]]; then
            val_ops=$(grep -E "finished [0-9]+ ops" "$LATEST_STDOUT_LOG" | tail -n 1 | sed -n 's/.*finished \([0-9]*\) ops.*/\1/p')
            ops_matrix["$row_label,$policy"]=$val_ops
        fi
    done
done

# --- Phase 2: Advanced Row Sorting ---

# We generate a sortable string: [priority] [x_value] [y_value_or_zero] [original_label]
# Priority 1: y is numeric
# Priority 2: y is "no"
sorted_rows=$(for r in "${!all_rows[@]}"; do
    curr_x="${r%->*}"
    curr_y="${r#*->}"
    
    if [[ "$curr_y" == "no" ]]; then
        echo "2 $curr_x 0 $r"
    else
        echo "1 $curr_x $curr_y $r"
    fi
done | sort -k1,1n -k2,2n -k3,3n | awk '{print $NF}')

sorted_policies=$(echo "${!all_policies[@]}" | tr ' ' '\n' | sort)

# --- Phase 3: Writing CSVs ---

for type in reset_count gc_movement ops_count; do
    file="${type}.csv"
    
    # Write Header
    header="label"
    for p in $sorted_policies; do header="${header},${p}"; done
    echo "$header" > "$file"

    # Write Rows in the custom sorted order
    for r in $sorted_rows; do
        row_str="$r"
        for p in $sorted_policies; do
            case $type in
                reset_count) val=${reset_matrix["$r,$p"]} ;;
                gc_movement) val=${gc_matrix["$r,$p"]} ;;
                ops_count)   val=${ops_matrix["$r,$p"]} ;;
            esac
            row_str="${row_str},${val}"
        done
        echo "$row_str" >> "$file"
    done
done

echo "CSV files generated with custom row sorting (Numeric Y first, then 'no' Y)."