#!/bin/bash

# Controllo formato con grep invece di [[ =~ ]]
if ! echo "$1" | grep -qiE '^#?[0-9a-f]{6}$'; then
    echo "Uso: $0 #RRGGBB"
    exit 1
fi

# Rimuove "#" se presente
hex="${1#\#}"

# Estrae RGB
r=$((16#${hex:0:2}))
g=$((16#${hex:2:2}))
b=$((16#${hex:4:2}))

# Truecolor tmux
truecolor="#$hex"

# Conversione RGB → 256 ANSI
ansi256=$(awk -v r=$r -v g=$g -v b=$b 'BEGIN {
    r = int(r / 51)
    g = int(g / 51)
    b = int(b / 51)
    print 16 + (36 * r) + (6 * g) + b
}')

# Output finale
echo "🎨 Colore HEX:        #$hex"
echo "✅ Tmux truecolor:    fg=#$hex"
echo "📦 Tmux 256-color:    fg=colour$ansi256"

