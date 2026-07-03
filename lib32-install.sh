#!/bin/bash

echo "Recupero elenco pacchetti lib32..."

mapfile -t multilib < <(pacman -Slq multilib | grep '^lib32-')

declare -A available
for pkg in "${multilib[@]}"; do
    available["$pkg"]=1
done

packages=()

while read -r pkg; do
    [[ $pkg == lib32-* ]] && continue
    echo "adesso -> $pkg"

    lib32="lib32-$pkg"

    [[ -z ${available[$lib32]} ]] && continue

    pacman -Q "$lib32" &>/dev/null && continue

    packages+=("$lib32")

done < <(pacman -Qq)

if ((${#packages[@]} == 0)); then
    echo
    echo "Nessun pacchetto lib32 da installare"
    exit 0
fi

echo
echo "Verrano installati ${#packages[@]} pacchetti:"
printf '   %s\n' "${packages[@]}"

echo
read -rp "Procedere [y/N] " ans

if [[ $ans =~ ^[Yy]([Ee][Ss])?$ ]]; then
    sudo pacman -S --needed "${packages[@]}"
else
    echo "Operazione annulata"
fi

