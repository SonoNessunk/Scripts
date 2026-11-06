#!/usr/bin/env bash

set -euo pipefail

# 0. Clean up any leftover links from previous runs
pw-link -d VirtualSpeaker:monitor_FL VirtualMic:input_FL 2>/dev/null || true
pw-link -d VirtualSpeaker:monitor_FR VirtualMic:input_FR 2>/dev/null || true

# 1. Clean up previous instances to prevent duplicate nodes
for id in $(pactl list short modules | awk '/module-null-sink/ && /Virtual/ {print $1}'); do
    pactl unload-module "$id" 2>/dev/null || true
done

# 2. Create virtual devices (Speaker and Mic)
pactl load-module module-null-sink sink_name="VirtualSpeaker" sink_properties=device.description=VirtualSpeaker >/dev/null
pactl load-module module-null-sink media.class=Audio/Source/Virtual sink_name="VirtualMic" channel_map=front-left,front-right >/dev/null

# 3. Wait and link audio channels (5-second timeout)
counter=0
max_attempts=25

until pw-link VirtualSpeaker:monitor_FL VirtualMic:input_FL 2>/dev/null && \
      pw-link VirtualSpeaker:monitor_FR VirtualMic:input_FR 2>/dev/null; do
    sleep 0.2
    counter=$((counter+1))
    if [ $counter -gt "$max_attempts" ]; then
        echo "Error: Unable to link PipeWire audio ports within timeout." >&2
        notify-send -u critical "Virtual Audio Error" "Failed to link virtual audio ports"
        exit 1
    fi
done

notify-send "Virtual Audio" "Virtual audio synced and ready"
