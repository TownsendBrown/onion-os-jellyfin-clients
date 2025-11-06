#!/bin/sh

sysdir=/mnt/SDCARD/.tmp_update
PATH="$sysdir/bin:$PATH"
LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$sysdir/lib:$sysdir/lib/parasyte"

APPDIR="/mnt/SDCARD/App/JellyfinMoviePlayer-Testing"
CONFIG_FILE="$APPDIR/jellyfin_config.txt"
DATA_DIR="$APPDIR/data"

load_config() {
    for config in "$CONFIG_FILE" "$APPDIR/jellyfin_config.txt" "/mnt/SDCARD/jellyfin_config.txt"; do
        if [ -f "$config" ]; then
            . "$config"
            [ "$config" != "$CONFIG_FILE" ] && cp "$config" "$CONFIG_FILE"
            return 0
        fi
    done
    return 1
}

save_config() {
    local server="$1"
    local api_key="$2"
    local user_id="${3:-}"
    
    mkdir -p "$DATA_DIR"
    cat > "$CONFIG_FILE" << EOF
SERVER_URL="$server"
API_KEY="$api_key"
EOF
    [ -n "$user_id" ] && echo "USER_ID=\"$user_id\"" >> "$CONFIG_FILE"
}

get_user_id() {
    [ -n "$USER_ID" ] && echo "$USER_ID" && return 0
    
    local response=$(curl -k -s "$SERVER_URL/Users" -H "$(get_auth_header)")
    local user_id=$(echo "$response" | grep -o '"Id":"[^"]*"' | head -1 | sed 's/"Id":"//;s/"//')
    
    if [ -n "$user_id" ]; then
        USER_ID="$user_id"
        echo "USER_ID=\"$user_id\"" >> "$CONFIG_FILE"
        echo "$user_id"
        return 0
    fi
    return 1
}

get_auth_header() {
    load_config
    [ -n "$API_KEY" ] && echo "Authorization: MediaBrowser Token=\"$API_KEY\""
}

jellyfin_get_movies() {
    load_config
    local user_id=$(get_user_id)
    curl -k -s "$SERVER_URL/Items?IncludeItemTypes=Movie&Recursive=true&Fields=PrimaryImageAspectRatio,Path&UserId=$user_id" -H "$(get_auth_header)"
}

parse_movie_list() {
    local input_file="$1"
    [ -f "$input_file" ] && jq -r '.Items[] | "\(.Id)|\(.Name)"' "$input_file"
}

jellyfin_test_connection() {
    local server="${1%/}"
    local response=$(curl -k -s -o /dev/null -w "%{http_code}" "$server/System/Info/Public")
    [ "$response" = "200" ]
}

jellyfin_test_api_key() {
    local server="${1%/}"
    local api_key="$2"
    local response=$(curl -k -s -o /dev/null -w "%{http_code}" "$server/Users" -H "Authorization: MediaBrowser Token=\"$api_key\"")
    [ "$response" = "200" ]
}

