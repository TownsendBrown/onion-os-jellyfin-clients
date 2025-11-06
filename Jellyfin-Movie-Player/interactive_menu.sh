#!/bin/sh

sysdir=/mnt/SDCARD/.tmp_update
PATH="$sysdir/bin:$PATH"
LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$sysdir/lib:$sysdir/lib/parasyte"

APPDIR="/mnt/SDCARD/App/JellyfinMoviePlayer-Testing"
DATA_DIR="$APPDIR/data"

cd "$APPDIR"
. ./jellyfin_api.sh
. ./browse.sh

while true; do
    clear
    
    if ! load_config 2>/dev/null; then
        action=$(echo -e "Setup Server\nExit" | $sysdir/script/shellect.sh -t "Jellyfin Movie Player" -b "A: Select  |  B: Back")
        
        if [ -z "$action" ] || [ "$action" = "Exit" ]; then
            exit 0
        elif [ "$action" = "Setup Server" ]; then
            sh "$APPDIR/setup.sh"
        fi
    else
        action=$(echo -e "Browse Movies\nRefresh Library\nExit" | $sysdir/script/shellect.sh -t "Jellyfin Movie Player" -b "A: Select  |  B: Back")
        
        if [ -z "$action" ]; then
            exit 0
        fi
        
        case "$action" in
            "Browse Movies")
                clear
                browse_library
                [ $? -eq 99 ] && exit 99
                sleep 0.2
                ;;
            "Refresh Library")
                clear
                refresh_library
                refresh_retval=$?
                
                if [ -f "$DATA_DIR/refresh_result.txt" ]; then
                    result=$(cat "$DATA_DIR/refresh_result.txt")
                    clear
                    echo ""
                    echo "==================================="
                    echo "    REFRESH COMPLETE"
                    echo "==================================="
                    echo ""
                    echo "$result"
                    echo ""
                    echo ""
                    read -n 1 -s -r -p "Press A to continue"
                else
                    clear
                    echo ""
                    echo "==================================="
                    echo "    REFRESH FAILED"
                    echo "==================================="
                    echo ""
                    echo "Check WiFi and server settings"
                    echo ""
                    sleep 2
                fi
                sleep 0.2
                ;;
            "Exit")
                exit 0
                ;;
        esac
    fi
done

