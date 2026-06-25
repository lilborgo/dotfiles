#!/usr/bin/env bash
# Waybar custom/notification module backed by dunst.
# Emits JSON: bell glyph + unread count, and a class reflecting DND state.

count=$(dunstctl count waiting 2>/dev/null || echo 0)
paused=$(dunstctl is-paused 2>/dev/null || echo false)

if [ "$paused" = "true" ]; then
    icon="󰂛"                       # bell-off (Do Not Disturb)
    class="dnd"
    if [ "${count:-0}" -gt 0 ]; then
        text="$icon $count"
        tip="Do Not Disturb — $count waiting"
    else
        text="$icon"
        tip="Do Not Disturb"
    fi
else
    icon="󰂚"                       # bell
    class="active"
    if [ "${count:-0}" -gt 0 ]; then
        text="$icon $count"
        tip="$count notification(s) waiting"
    else
        text="$icon"
        tip="No notifications"
    fi
fi

printf '{"text":"%s","class":"%s","tooltip":"%s"}\n' "$text" "$class" "$tip"
