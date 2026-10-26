#!/usr/bin/env bash

#echo "VirtualSpeaker"
# Create a virtual sink that can be set as a monitor in OBS
#pactl load-module module-null-sink sink_name="VirtualSpeaker" sink_properties=device.description=VirtualSpeaker
#echo " "
#echo "VirtualMic"
# Link it with a virtual source that is visible in pulseaudio apps like Zoom
#pactl load-module module-null-sink media.class=Audio/Source/Virtual sink_name="VirtualMic" channel_map=front-left,front-right
#echo " "
#echo "Linking together"
#pw-link VirtualSpeaker:monitor_FL VirtualMic:input_FL
#pw-link VirtualSpeaker:monitor_FR VirtualMic:input_FR
#echo " "
#echo "Loopback"
#Add loopback to hear comment out if you wish to disable
#pactl load-module module-loopback sink_name="LoopbackSync" source="VirtualSpeaker.monitor"
#notify-send "🎧 Audio Virtuale" "Speaker e microfono virtuali attivati"

pactl load-module module-null-sink sink_name="VirtualSpeaker" sink_properties=device.description=VirtualSpeaker
pactl load-module module-null-sink media.class=Audio/Source/Virtual sink_name="VirtualMic" channel_map=front-left,front-right

# Tenta il collegamento finché le porte non sono pronte (con timeout di sicurezza)
counter=0
until pw-link VirtualSpeaker:monitor_FL VirtualMic:input_FL 2>/dev/null; do
    sleep 0.2
    counter=$((counter+1))
    if [ $counter -gt 25 ]; then
        echo "Errore: impossibile collegare i nodi audio in tempo."
        exit 1
    fi
done

pw-link VirtualSpeaker:monitor_FR VirtualMic:input_FR
echo "Audio virtuale collegato con successo!"
