#!/bin/bash
###############
### VECCHIO ###
###############

# Aspetta che il dispositivo sia prontos
#adb tcpip 5555
#adb disconnect
#adb connect 192.168.1.100

# Avvia scrcpy
# scrcpy -w --no-mouse-hover --audio-dup -b 16M -e -G
# scrcpy -w --no-mouse-hover -b 16M -e -G
#scrcpy -w --no-mouse-hover -K -b 16M -e --tcpip -m 1168
#scrcpy -w --no-mouse-hover -K -b 32M -e --tcpip
#scrcpy -w --no-mouse-hover -K -b 8M -e --tcpip

#############
### NUOVO ###
#############

TARGET_IP="${1:-192.168.1.100}"
TARGET="$TARGET_IP:5555"

adb start-server >/dev/null 2>&1

echo "Verifico connessione su $TARGET..."

if ! adb devices | grep -q "$TARGET"; then
    timeout 3 adb connect "$TARGET" >/dev/null 2>&1
fi

echo "Avvio scrcpy su $TARGET"

scrcpy -s "$TARGET" -w --no-mouse-hover -K -b 8M -G