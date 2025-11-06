#!/bin/sh

sysdir=/mnt/SDCARD/.tmp_update
PATH="$sysdir/bin:$PATH"
LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$sysdir/lib:$sysdir/lib/parasyte"

APPDIR="/mnt/SDCARD/App/JellyfinMoviePlayer-Testing"
DATA_DIR="$APPDIR/data"

cd "$APPDIR"
. ./jellyfin_api.sh

refresh_library() {
    mkdir -p "$DATA_DIR"
    
    if ! load_config 2>/dev/null; then
        return 1
    fi
    
    local movies_json=$(jellyfin_get_movies 2>/dev/null)
    
    if [ -z "$movies_json" ]; then
        return 1
    fi
    
    echo "$movies_json" > "$DATA_DIR/movies_raw.json"
    parse_movie_list "$DATA_DIR/movies_raw.json" > "$DATA_DIR/movies_list.txt" 2>/dev/null
    
    local count=$(wc -l < "$DATA_DIR/movies_list.txt" 2>/dev/null || echo 0)
    
    if [ "$count" -eq 0 ]; then
        return 1
    fi
    
    echo "SUCCESS - $count movies loaded" > "$DATA_DIR/refresh_result.txt"
    return 0
}

browse_library() {
    if [ ! -f "$DATA_DIR/movies_list.txt" ]; then
        clear
        echo ""
        echo "Library not initialized."
        echo "Please use 'Refresh Library' first."
        echo ""
        sleep 2
        return 1
    fi
    
    local count=$(wc -l < "$DATA_DIR/movies_list.txt" 2>/dev/null || echo 0)
    
    if [ "$count" -eq 0 ]; then
        clear
        echo ""
        echo "Library is empty."
        echo "Please use 'Refresh Library'."
        echo ""
        sleep 2
        return 1
    fi
    
    local movie_list=""
    while IFS='|' read -r id name; do
        [ -z "$name" ] && continue
        if [ -z "$movie_list" ]; then
            movie_list="$name"
        else
            movie_list="$movie_list\n$name"
        fi
    done < "$DATA_DIR/movies_list.txt"
    
    if [ -z "$movie_list" ]; then
        clear
        echo ""
        echo "Error building movie list."
        echo ""
        sleep 2
        return 1
    fi
    
    selected_movie=$(echo -e "$movie_list" | /mnt/SDCARD/.tmp_update/script/shellect.sh -t "Browse Movies ($count)" -b "A: Play  |  B: Back")
    
    [ -z "$selected_movie" ] && return 0
    
    local movie_id=$(grep -F "|$selected_movie" "$DATA_DIR/movies_list.txt" | head -1 | cut -d'|' -f1)
    
    if [ -z "$movie_id" ]; then
        infoPanel --title "Error" --message "Could not find movie." &
        sleep 2
        return 1
    fi
    
    infoPanel --title "Starting Playback" --message "Loading: $selected_movie\n\nBuffering may take\n30-60 seconds..." &
    sleep 2
    
    echo "$movie_id" > "$DATA_DIR/play_request.tmp"
    echo "$selected_movie" >> "$DATA_DIR/play_request.tmp"
    
    return 99
}

if [ -n "$1" ]; then
    [ "$1" = "--refresh" ] && refresh_library || browse_library
fi

