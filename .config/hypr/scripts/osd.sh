#!/usr/bin/env bash
# Adjusts volume / brightness and shows an in-place dunst OSD with a progress bar.
# Usage: osd.sh {volume-up|volume-down|volume-mute|brightness-up|brightness-down}

SINK="@DEFAULT_AUDIO_SINK@"

notify() {
    # $1 = title, $2 = value (0-100), $3 = icon name
    notify-send -a OSD -u low -t 1500 \
        -h string:x-canonical-private-synchronous:osd \
        -h "int:value:$2" \
        -i "$3" "$1"
}

volume_osd() {
    read -r _ vol muted < <(wpctl get-volume "$SINK")
    pct=$(awk -v v="$vol" 'BEGIN { printf "%d", v * 100 }')
    if [ -n "$muted" ]; then
        notify "Muted" 0 audio-volume-muted
    else
        if   [ "$pct" -eq 0 ];  then icon=audio-volume-muted
        elif [ "$pct" -lt 34 ]; then icon=audio-volume-low
        elif [ "$pct" -lt 67 ]; then icon=audio-volume-medium
        else                          icon=audio-volume-high
        fi
        notify "Volume  ${pct}%" "$pct" "$icon"
    fi
}

brightness_osd() {
    pct=$(brightnessctl -m | cut -d, -f4 | tr -d '%')
    notify "Brightness  ${pct}%" "$pct" display-brightness
}

case "$1" in
    volume-up)
        wpctl set-volume -l 1 "$SINK" 5%+ ; volume_osd ;;
    volume-down)
        wpctl set-volume "$SINK" 5%- ; volume_osd ;;
    volume-mute)
        wpctl set-mute "$SINK" toggle ; volume_osd ;;
    brightness-up)
        brightnessctl -e4 -n2 set 5%+ ; brightness_osd ;;
    brightness-down)
        brightnessctl -e4 -n2 set 5%- ; brightness_osd ;;
    *)
        echo "usage: $0 {volume-up|volume-down|volume-mute|brightness-up|brightness-down}" >&2
        exit 1 ;;
esac
