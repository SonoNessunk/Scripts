#!/bin/bash
# Aspetta che il dispositivo sia prontos
adb tcpip 5555
adb disconnect
adb connect 192.168.1.100

# Avvia scrcpy
# scrcpy -w --no-mouse-hover --audio-dup -b 16M -e -G
# scrcpy -w --no-mouse-hover -b 16M -e -G
# scrcpy -w --no-mouse-hover -K -b 16M -e --tcpip -m 1168
scrcpy -w --no-mouse-hover -K -b 32M -e --tcpip
