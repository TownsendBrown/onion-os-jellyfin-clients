#!/bin/sh

sysdir=/mnt/SDCARD/.tmp_update
PATH="$sysdir/bin:$PATH"
LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$sysdir/lib:$sysdir/lib/parasyte"

APPDIR="/mnt/SDCARD/App/JellyfinShowPlayer-Testing"
DATA_DIR="$APPDIR/data"

cd "$APPDIR"
. ./jellyfin_api.sh

refresh_library() {
    mkdir -p "$DATA_DIR"
    
    if ! load_config 2>/dev/null; then
        return 1
    fi
    
    local shows_json=$(jellyfin_get_shows 2>/dev/null)
    
    if [ -z "$shows_json" ]; then
        return 1
    fi
    
    echo "$shows_json" > "$DATA_DIR/shows_raw.json"
    parse_show_list "$DATA_DIR/shows_raw.json" > "$DATA_DIR/shows_list_temp.txt" 2>/dev/null
    
    awk -F'|' '!seen[$2]++' "$DATA_DIR/shows_list_temp.txt" > "$DATA_DIR/shows_list.txt"
    
    local count=$(wc -l < "$DATA_DIR/shows_list.txt" 2>/dev/null || echo 0)
    
    if [ "$count" -eq 0 ]; then
        return 1
    fi
    
    echo "SUCCESS - $count TV shows loaded" > "$DATA_DIR/refresh_result.txt"
    return 0
}

browse_library() {
    if [ ! -f "$DATA_DIR/shows_list.txt" ]; then
        clear
        echo ""
        echo "Library not initialized."
        echo "Please use 'Refresh Library' first."
        echo ""
        sleep 2
        return 1
    fi
    
    browse_shows
    return $?
}

browse_shows() {
    local count=$(wc -l < "$DATA_DIR/shows_list.txt" 2>/dev/null || echo 0)
    
    if [ "$count" -eq 0 ]; then
        clear
        echo ""
        echo "Library is empty."
        echo "Please use 'Refresh Library'."
        echo ""
        sleep 2
        return 1
    fi
    
    local show_list=""
    while IFS='|' read -r id name; do
        [ -z "$name" ] && continue
        if [ -z "$show_list" ]; then
            show_list="$name"
        else
            show_list="$show_list\n$name"
        fi
    done < "$DATA_DIR/shows_list.txt"
    
    if [ -z "$show_list" ]; then
        return 1
    fi
    
    selected_show=$(echo -e "$show_list" | /mnt/SDCARD/.tmp_update/script/shellect.sh -t "Browse TV Shows ($count)" -b "A: Select  |  B: Back")
    
    [ -z "$selected_show" ] && return 0
    
    local show_id=$(grep -F "|$selected_show" "$DATA_DIR/shows_list.txt" | head -1 | cut -d'|' -f1)
    
    if [ -z "$show_id" ]; then
        return 1
    fi
    
    browse_seasons "$show_id" "$selected_show"
    return $?
}

browse_seasons() {
    local show_id="$1"
    local show_name="$2"
    
    local seasons_json=$(jellyfin_get_seasons "$show_id" 2>/dev/null)
    
    if [ -z "$seasons_json" ]; then
        clear
        echo ""
        echo "Failed to fetch seasons."
        echo ""
        sleep 2
        return 1
    fi
    
    echo "$seasons_json" > "$DATA_DIR/seasons_temp.json"
    parse_show_list "$DATA_DIR/seasons_temp.json" > "$DATA_DIR/seasons_temp.txt" 2>/dev/null
    
    local season_count=$(wc -l < "$DATA_DIR/seasons_temp.txt" 2>/dev/null || echo 0)
    
    if [ "$season_count" -eq 0 ]; then
        local direct_episodes_json=$(jellyfin_get_episodes "$show_id" "$show_id" 2>/dev/null)
        
        if [ -n "$direct_episodes_json" ]; then
            echo "$direct_episodes_json" > "$DATA_DIR/episodes_temp.json"
            parse_show_list "$DATA_DIR/episodes_temp.json" > "$DATA_DIR/episodes_temp.txt" 2>/dev/null
            local episode_count=$(wc -l < "$DATA_DIR/episodes_temp.txt" 2>/dev/null || echo 0)
            
            if [ "$episode_count" -gt 0 ]; then
                browse_episodes_direct "$show_id" "$show_name"
                return $?
            fi
        fi
        
        clear
        echo ""
        echo "No seasons or episodes found."
        echo ""
        sleep 2
        return 1
    fi
    
    local season_list=""
    while IFS='|' read -r id name; do
        [ -z "$name" ] && continue
        if [ -z "$season_list" ]; then
            season_list="$name"
        else
            season_list="$season_list\n$name"
        fi
    done < "$DATA_DIR/seasons_temp.txt"
    
    selected_season=$(echo -e "$season_list" | /mnt/SDCARD/.tmp_update/script/shellect.sh -t "$show_name" -b "A: Select  |  B: Back")
    
    [ -z "$selected_season" ] && return 0
    
    local season_id=$(grep -F "|$selected_season" "$DATA_DIR/seasons_temp.txt" | head -1 | cut -d'|' -f1)
    
    if [ -z "$season_id" ]; then
        return 1
    fi
    
    browse_episodes "$show_id" "$season_id" "$show_name" "$selected_season"
    return $?
}

browse_episodes() {
    local show_id="$1"
    local season_id="$2"
    local show_name="$3"
    local season_name="$4"
    
    local episodes_json=$(jellyfin_get_episodes "$show_id" "$season_id" 2>/dev/null)
    
    if [ -z "$episodes_json" ]; then
        clear
        echo ""
        echo "Failed to fetch episodes."
        echo ""
        sleep 2
        return 1
    fi
    
    echo "$episodes_json" > "$DATA_DIR/episodes_temp.json"
    parse_show_list "$DATA_DIR/episodes_temp.json" > "$DATA_DIR/episodes_temp.txt" 2>/dev/null
    
    local episode_count=$(wc -l < "$DATA_DIR/episodes_temp.txt" 2>/dev/null || echo 0)
    
    if [ "$episode_count" -eq 0 ]; then
        clear
        echo ""
        echo "No episodes found."
        echo ""
        sleep 2
        return 1
    fi
    
    local episode_list=""
    while IFS='|' read -r id name; do
        [ -z "$name" ] && continue
        if [ -z "$episode_list" ]; then
            episode_list="$name"
        else
            episode_list="$episode_list\n$name"
        fi
    done < "$DATA_DIR/episodes_temp.txt"
    
    selected_episode=$(echo -e "$episode_list" | /mnt/SDCARD/.tmp_update/script/shellect.sh -t "$show_name: $season_name" -b "A: Play  |  B: Back")
    
    [ -z "$selected_episode" ] && return 0
    
    local episode_id=$(grep -F "|$selected_episode" "$DATA_DIR/episodes_temp.txt" | head -1 | cut -d'|' -f1)
    
    if [ -z "$episode_id" ]; then
        return 1
    fi
    
    echo "$episode_id" > "$DATA_DIR/play_request.tmp"
    echo "$selected_episode" >> "$DATA_DIR/play_request.tmp"
    
    return 99
}

browse_episodes_direct() {
    local show_id="$1"
    local show_name="$2"
    
    local episode_count=$(wc -l < "$DATA_DIR/episodes_temp.txt" 2>/dev/null || echo 0)
    
    if [ "$episode_count" -eq 0 ]; then
        return 1
    fi
    
    local episode_list=""
    while IFS='|' read -r id name; do
        [ -z "$name" ] && continue
        if [ -z "$episode_list" ]; then
            episode_list="$name"
        else
            episode_list="$episode_list\n$name"
        fi
    done < "$DATA_DIR/episodes_temp.txt"
    
    selected_episode=$(echo -e "$episode_list" | /mnt/SDCARD/.tmp_update/script/shellect.sh -t "$show_name" -b "A: Play  |  B: Back")
    
    [ -z "$selected_episode" ] && return 0
    
    local episode_id=$(grep -F "|$selected_episode" "$DATA_DIR/episodes_temp.txt" | head -1 | cut -d'|' -f1)
    
    if [ -z "$episode_id" ]; then
        return 1
    fi
    
    echo "$episode_id" > "$DATA_DIR/play_request.tmp"
    echo "$selected_episode" >> "$DATA_DIR/play_request.tmp"
    
    return 99
}

if [ -n "$1" ]; then
    [ "$1" = "--refresh" ] && refresh_library || browse_library
fi
