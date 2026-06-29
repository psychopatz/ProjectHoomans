#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 <mod_name_or_keyword>"
    echo "Example: $0 bandit"
    exit 1
fi

SEARCH_TERM_ORIG="$1"
SEARCH_TERM=$(echo "$1" | tr '[:upper:]' '[:lower:]')
WORKSHOP_PATH="/home/psychopatz/.steam/debian-installation/steamapps/workshop/content/108600"

if [ ! -d "$WORKSHOP_PATH" ]; then
    echo "Error: Steam Workshop directory not found at $WORKSHOP_PATH"
    exit 1
fi

echo "Searching for mods matching: $SEARCH_TERM_ORIG"
echo "------------------------------------------------"

MATCHED_MODS=()

# Process all mods folders
while IFS= read -r MOD_DIR; do
    DIR_LOWER=$(basename "$MOD_DIR" | tr '[:upper:]' '[:lower:]')
    MATCH_FOUND=0
    
    # Check folder name first
    if [[ "$DIR_LOWER" == *"$SEARCH_TERM"* ]]; then
        MATCH_FOUND=1
    fi
    
    MOD_INFO="$MOD_DIR/mod.info"
    MOD_NAME=""
    MOD_ID=""
    MOD_DESC=""
    
    # Parse mod.info and search its contents if available
    if [ -f "$MOD_INFO" ]; then
        MOD_NAME=$(grep -m 1 "^name=" "$MOD_INFO" | cut -d'=' -f2- | tr -d '\r')
        MOD_ID=$(grep -m 1 "^id=" "$MOD_INFO" | cut -d'=' -f2- | tr -d '\r')
        MOD_DESC=$(grep -m 1 "^description=" "$MOD_INFO" | cut -d'=' -f2- | tr -d '\r')
        
        if [ "$MATCH_FOUND" -eq 0 ]; then
            NAME_LOWER=$(echo "$MOD_NAME" | tr '[:upper:]' '[:lower:]')
            DESC_LOWER=$(echo "$MOD_DESC" | tr '[:upper:]' '[:lower:]')
            ID_LOWER=$(echo "$MOD_ID" | tr '[:upper:]' '[:lower:]')
            
            if [[ "$NAME_LOWER" == *"$SEARCH_TERM"* ]] || [[ "$DESC_LOWER" == *"$SEARCH_TERM"* ]] || [[ "$ID_LOWER" == *"$SEARCH_TERM"* ]]; then
                MATCH_FOUND=1
            fi
        fi
    fi
    
    if [ "$MATCH_FOUND" -eq 1 ]; then
        # Store result with delimiter to avoid rescanning later
        MATCHED_MODS+=("$MOD_DIR|$MOD_NAME|$MOD_ID|$MOD_DESC")
    fi

done < <(find "$WORKSHOP_PATH" -mindepth 3 -maxdepth 3 -type d -path "*/mods/*")

RESULT_COUNT=${#MATCHED_MODS[@]}

if [ "$RESULT_COUNT" -eq 0 ]; then
    echo "No mods found matching: $SEARCH_TERM_ORIG"
    exit 0
fi

echo "Found $RESULT_COUNT mod(s) matching '$SEARCH_TERM_ORIG':"
echo ""

for MATCH in "${MATCHED_MODS[@]}"; do
    # Extract data using parameter expansion
    MOD_DIR="${MATCH%%|*}"
    REMAINING="${MATCH#*|}"
    MOD_NAME="${REMAINING%%|*}"
    REMAINING2="${REMAINING#*|}"
    MOD_ID="${REMAINING2%%|*}"
    MOD_DESC="${REMAINING2#*|}"
    
    echo "Path: $MOD_DIR"
    
    if [ -f "$MOD_DIR/mod.info" ]; then
        echo "  Name: ${MOD_NAME:-Unknown}"
        echo "  ID: ${MOD_ID:-Unknown}"
        if [ -n "$MOD_DESC" ]; then
            SHORT_DESC=$(echo "$MOD_DESC" | cut -c 1-150)
            if [ "${#MOD_DESC}" -gt 150 ]; then
                echo "  Description: $SHORT_DESC..."
            else
                echo "  Description: $SHORT_DESC"
            fi
        fi
    else
        echo "  (No mod.info found)"
    fi
    echo "------------------------------------------------"
done
