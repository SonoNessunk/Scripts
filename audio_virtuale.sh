#!/usr/bin/env bash

echo "VirtualSpeaker"
# Create a virtual sink that can be set as a monitor in OBS
pactl load-module module-null-sink sink_name="VirtualSpeaker" sink_properties=device.description=VirtualSpeaker
echo " "
echo "VirtualMic"
# Link it with a virtual source that is visible in pulseaudio apps like Zoom
pactl load-module module-null-sink media.class=Audio/Source/Virtual sink_name="VirtualMic" channel_map=front-left,front-right
echo " "
echo "Linking together"
pw-link VirtualSpeaker:monitor_FL VirtualMic:input_FL
pw-link VirtualSpeaker:monitor_FR VirtualMic:input_FR
echo " "
#echo "Loopback"
#Add loopback to hear comment out if you wish to disable
#pactl load-module module-loopback sink_name="LoopbackSync" source="VirtualSpeaker.monitor"
#notify-send "🎧 Audio Virtuale" "Speaker e microfono virtuali attivati"
