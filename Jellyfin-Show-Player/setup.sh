#!/bin/sh

sysdir=/mnt/SDCARD/.tmp_update
PATH="$sysdir/bin:$PATH"
LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$sysdir/lib:$sysdir/lib/parasyte"

APPDIR="/mnt/SDCARD/App/JellyfinShowPlayer-Testing"
DATA_DIR="$APPDIR/data"

cd "$APPDIR"
. ./jellyfin_api.sh

setup_jellyfin() {
    if load_config 2>/dev/null; then
        infoPanel --title "Testing Connection" --message "Checking server..." &
        local test_pid=$!
        
        if ! jellyfin_test_connection "$SERVER_URL"; then
            kill $test_pid 2>/dev/null
            touch /tmp/dismiss_info_panel
            sleep 0.2
            infoPanel --title "Connection Failed" --message "Could not connect to server.\nCheck WiFi and settings."
            return 1
        fi
        
        kill $test_pid 2>/dev/null
        touch /tmp/dismiss_info_panel
        sleep 0.2
        
        infoPanel --title "Authenticating" --message "Verifying API key..." &
        test_pid=$!
        
        if ! jellyfin_test_api_key "$SERVER_URL" "$API_KEY"; then
            kill $test_pid 2>/dev/null
            touch /tmp/dismiss_info_panel
            sleep 0.2
            infoPanel --title "Auth Failed" --message "Invalid API key."
            return 1
        fi
        
        kill $test_pid 2>/dev/null
        touch /tmp/dismiss_info_panel
        sleep 0.2
        
        infoPanel --title "Getting User Info" --message "Loading user info..." &
        test_pid=$!
        
        local user_id=$(get_user_id)
        kill $test_pid 2>/dev/null
        touch /tmp/dismiss_info_panel
        sleep 0.2
        
        if [ -z "$user_id" ]; then
            infoPanel --title "Error" --message "Could not get user info."
            return 1
        fi
        
        infoPanel --title "Setup Complete!" --message "Successfully connected!\n\nUse 'Refresh Library' to load shows."
        return 0
    fi
    
    infoPanel --title "Setup Required" --message "Create jellyfin_config.txt:\n\nSERVER_URL=\"http://server:8096\"\nAPI_KEY=\"your-key\""
    return 1
}

setup_jellyfin
