#!/bin/sh

sysdir=/mnt/SDCARD/.tmp_update
PATH="$sysdir/bin:$PATH"
LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$sysdir/lib:$sysdir/lib/parasyte"

APPDIR="/mnt/SDCARD/App/JellyfinShowPlayer-Testing"
DATA_DIR="$APPDIR/data"

cd "$APPDIR"
. ./jellyfin_api.sh

cleanup_playback() {
    pkill -9 curl 2>/dev/null
    pkill -9 ffplay 2>/dev/null
    rm -f /tmp/stay_awake 2>/dev/null
    touch /tmp/dismiss_info_panel
    sleep 0.1
    echo ondemand > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null
}

play_video() {
    local item_id="$1"
    local title="$2"
    
    [ -z "$item_id" ] && return 1
    
    cleanup_playback
    load_config
    
    local device_id="miyoo_mini_plus"
    local stream_url="$SERVER_URL/Videos/$item_id/stream?Static=false&MediaSourceId=$item_id&DeviceId=$device_id&VideoCodec=h264&AudioCodec=aac&VideoBitrate=500000&AudioBitrate=96000&MaxWidth=640&MaxHeight=480&api_key=$API_KEY"
    
    echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null
    touch /tmp/stay_awake
    
    pkill infoPanel 2>/dev/null
    touch /tmp/dismiss_info_panel
    sleep 0.3
    touch /tmp/dismiss_info_panel
    sleep 0.5
    
    cd "$sysdir"
    
    ./bin/curl -k -L --limit-rate 1M --max-time 0 "$stream_url" 2>/dev/null | \
        ./bin/ffplay -autoexit -vf "hflip,vflip" -af "pan=stereo|FL<FC+0.30*FL+0.30*BL|FR<FC+0.30*FR+0.30*BR" - 2>/dev/null &
    
    playback_pid=$!
    wait $playback_pid
    playback_result=$?
    
    pkill -9 curl 2>/dev/null
    pkill -9 ffplay 2>/dev/null
    touch /tmp/dismiss_info_panel
    sleep 0.3
    
    cleanup_playback
    
    if [ $playback_result -eq 123 ]; then
        infoPanel --title "Playback Failed" --message "Video failed to start.\nCheck WiFi connection." &
        sleep 2
    fi
    
    return 0
}

[ -n "$1" ] && play_video "$1" "$2"
