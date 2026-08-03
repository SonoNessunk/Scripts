#!/bin/bash

echo "Fetching lib32 package list..."

mapfile -t multilib < <(pacman -Slq multilib | grep '^lib32-')

declare -A available
for pkg in "${multilib[@]}"; do
    available["$pkg"]=1
done

packages=()
convert=()

while read -r pkg; do
    [[ $pkg == lib32-* ]] && continue
    echo "Check -> $pkg"

    lib32="lib32-$pkg"

    [[ -z ${available[$lib32]} ]] && continue

    if pacman -Q "$lib32" &>/dev/null; then
        reason=$(pacman -Qi "$lib32" | awk -F': ' '/Install Reason/ {print $2}')

        if [[ "$reason" == "Explicitly installed" ]]; then
            convert+=("$lib32")
        fi

        continue
    fi

    packages+=("$lib32")

done < <(pacman -Qq)

if ((${#convert[@]})); then
    echo
    echo "Converting to dependencies:"
    printf '   %s\n' "${convert[@]}"
fi

if ((!${#convert[@]} && !${#packages[@]})); then
    echo "No lib32 packages to modify/install"
    exit 0
fi

echo
echo "${#packages[@]} packages will be installed:"
printf '   %s\n' "${packages[@]}"

echo
read -rp "Proceed [y/N] " ans

if [[ $ans =~ ^[Yy]([Ee][Ss])?$ ]]; then
    ((${#convert[@]})) && sudo pacman -D --asdeps "${convert[@]}"
    ((${#packages[@]})) && sudo pacman -S --asdeps --needed "${packages[@]}"
else
    echo "Operation cancelled"
fi

