#!/bin/bash
# Aspetta che il dispositivo sia prontos
adb tcpip 5555
adb disconnect
adb connect 192.168.1.100

# Avvia scrcpy
#scrcpy --stay-awake --no-mouse-hover --audio-dup --video-bit-rate 16M -e -G
scrcpy --stay-awake --no-mouse-hover --video-bit-rate 16M -e -G
