#!/bin/sh

APPDIR="/mnt/SDCARD/App/JellyfinMoviePlayer-Testing"
SYSDIR="/mnt/SDCARD/.tmp_update"
DATA_DIR="$APPDIR/data"

pkill -9 curl 2>/dev/null
pkill -9 ffplay 2>/dev/null
rm -f /tmp/stay_awake 2>/dev/null

while true; do
    cd "$SYSDIR"
    ./bin/st -q -e sh "$APPDIR/interactive_menu.sh"
    retval=$?
    
    if [ $retval -eq 99 ] && [ -f "$DATA_DIR/play_request.tmp" ]; then
        movie_id=$(sed -n '1p' "$DATA_DIR/play_request.tmp")
        movie_name=$(sed -n '2p' "$DATA_DIR/play_request.tmp")
        rm -f "$DATA_DIR/play_request.tmp"
        sh "$APPDIR/play.sh" "$movie_id" "$movie_name"
        sleep 0.5
    else
        pkill -9 curl 2>/dev/null
        pkill -9 ffplay 2>/dev/null
        rm -f /tmp/stay_awake 2>/dev/null
        exit 0
    fi
done

