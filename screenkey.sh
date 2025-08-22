#!/bin/bash
# Avvia screenkey su entrambi gli schermi

# Primo monitor
GDK_BACKEND=x11 screenkey --position fixed --geometry 510x110+1400+900 &

# Secondo monitor
GDK_BACKEND=x11 screenkey --position fixed --geometry 510x110+3320+900 &
