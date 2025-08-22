#!/bin/bash

# Nome dei nodi
SINK="VirtualSpeaker"
MIC="VirtualMic"

echo "🎧 Creazione Virtual Speaker"
pw-cli create-node adapter \
"{ factory.name=support.null-audio-sink node.name=$SINK media.class=Audio/Sink object.linger=true }"

echo "🎤 Creazione Virtual Microphone"
pw-cli create-node adapter \
"{ factory.name=support.null-audio-sink node.name=$MIC media.class=Audio/Source object.linger=true }"

echo "🔗 Collegamento monitor sink -> input mic"
pw-link ${SINK}:monitor_FL ${MIC}:input_FL
pw-link ${SINK}:monitor_FR ${MIC}:input_FR

echo "🔊 Loopback (opzionale, da commentare se non vuoi sentire)"
pw-loopback --capture-source=${SINK}:monitor --playback-sink=alsa_output.pci-0000_00_1f.3.analog-stereo &

notify-send "🎧 Audio Virtuale" "Speaker e microfono virtuali attivati"
