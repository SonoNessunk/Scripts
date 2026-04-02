#!/usr/bin/env bash

HWMON="/sys/class/hwmon/hwmon3/device"

# ── Colori ──────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

# ── Controlla root ───────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}Errore:${RESET} esegui con sudo."
    exit 1
fi

# ── Funzioni helper ──────────────────────────────────────

# Legge il valore di un file sysfs, ritorna "N/A" se non esiste
read_sysfs() {
    local path="$1"
    [[ -r "$path" ]] && cat "$path" 2>/dev/null || echo "N/A"
}

# Converte valore PWM (0-255) in percentuale
pwm_to_pct() {
    local pwm="$1"
    [[ "$pwm" == "N/A" ]] && echo "N/A" && return
    printf "%.0f" "$(echo "scale=2; $pwm * 100 / 255" | bc)"
}

# Converte percentuale in valore PWM (0-255)
pct_to_pwm() {
    local pct="$1"
    printf "%.0f" "$(echo "scale=2; $pct * 255 / 100" | bc)"
}

# Legge lo stato enable e lo mostra in modo leggibile
enable_label() {
    case "$1" in
        0) echo -e "${RED}OFF${RESET}" ;;
        1) echo -e "${YELLOW}MANUALE${RESET}" ;;
        2) echo -e "${GREEN}AUTO${RESET}" ;;
        *) echo "Sconosciuto ($1)" ;;
    esac
}

# ── Mostra stato attuale ─────────────────────────────────
show_status() {
    clear
    echo -e "\n${BOLD}${CYAN}══════════════════════════════${RESET}"
    echo -e "${BOLD}  Stato ventole — $HWMON${RESET}"
    echo -e "${BOLD}${CYAN}══════════════════════════════${RESET}"

    for i in 1 2 3; do
        local pwm_path="$HWMON/pwm$i"
        local enable_path="$HWMON/pwm${i}_enable"
        local fan_path="$HWMON/fan${i}_input"

        # Salta se il file pwm non esiste
        [[ ! -e "$pwm_path" ]] && continue

        local pwm_val enable_val rpm pct mode
        pwm_val=$(read_sysfs "$pwm_path")
        enable_val=$(read_sysfs "$enable_path")
        rpm=$(read_sysfs "$fan_path")
        pct=$(pwm_to_pct "$pwm_val")
        mode=$(enable_label "$enable_val")

        echo -e "\n  ${BOLD}Ventola $i${RESET}"
        echo -e "    Modalità : $mode"
        echo -e "    PWM      : ${pwm_val}/255 (${pct}%)"
        echo -e "    RPM      : ${rpm} giri/min"
    done

    echo -e "\n${BOLD}${CYAN}══════════════════════════════${RESET}\n"
}

# ── Imposta modalità (auto/manuale) per una ventola ─────
set_mode() {
    local fan="$1"   # numero ventola (1, 2, 3)
    local mode="$2"  # "auto" o "manual"
    local enable_path="$HWMON/pwm${fan}_enable"

    [[ ! -e "$enable_path" ]] && echo -e "${RED}pwm${fan}_enable non trovato.${RESET}" && return 1

    local val
    [[ "$mode" == "auto" ]] && val=2 || val=1

    echo "$val" > "$enable_path"
    local result=$?

    if [[ $result -ne 0 ]]; then
        # Alcuni driver non supportano mode 2, prova con 0
        echo -e "${YELLOW}Attenzione:${RESET} mode $val non supportato, provo con 0..."
        echo "0" > "$enable_path"
    fi

    echo -e "  Ventola $fan → $(enable_label "$val")"
}

# ── Imposta velocità manuale ─────────────────────────────
set_speed() {
    local fan="$1"   # numero ventola
    local pct="$2"   # percentuale 0-100
    local pwm_path="$HWMON/pwm${fan}"
    local enable_path="$HWMON/pwm${fan}_enable"

    [[ ! -e "$pwm_path" ]] && echo -e "${RED}pwm${fan} non trovato.${RESET}" && return 1

    # Prima metti in modalità manuale
    echo "1" > "$enable_path"

    local pwm_val
    pwm_val=$(pct_to_pwm "$pct")

    # Clamp tra 0 e 255
    (( pwm_val < 0 ))   && pwm_val=0
    (( pwm_val > 255 )) && pwm_val=255

    echo "$pwm_val" > "$pwm_path"
    echo -e "  Ventola $fan → ${pct}% (PWM ${pwm_val}/255)"
}

# ── Menu interattivo ─────────────────────────────────────
menu() {
    while true; do
        show_status
        echo -e "${BOLD}Cosa vuoi fare?${RESET}"
        echo "  1) Metti una ventola in AUTO"
        echo "  2) Metti una ventola in MANUALE + imposta velocità"
        echo "  3) Imposta velocità (ventola già in manuale)"
        echo "  4) Metti TUTTE le ventole in AUTO"
        echo "  5) Metti TUTTE le ventole al 100% (manuale)"
        echo "  q) Esci"
        echo
        read -rp "Scelta: " choice

        case "$choice" in
            1)
                read -rp "  Numero ventola (1/2/3): " fn
                set_mode "$fn" "auto"
                ;;
            2)
                read -rp "  Numero ventola (1/2/3): " fn
                read -rp "  Velocità % (0-100): " sp
                set_speed "$fn" "$sp"
                ;;
            3)
                read -rp "  Numero ventola (1/2/3): " fn
                read -rp "  Velocità % (0-100): " sp
                set_speed "$fn" "$sp"
                ;;
            4)
                for i in 1 2 3; do
                    [[ -e "$HWMON/pwm${i}_enable" ]] && set_mode "$i" "auto"
                done
                ;;
            5)
                for i in 1 2 3; do
                    [[ -e "$HWMON/pwm${i}" ]] && set_speed "$i" 100
                done
                ;;
            q|Q)
                echo -e "\n${GREEN}Uscito.${RESET}\n"
                exit 0
                ;;
            *)
                echo -e "${RED}Scelta non valida.${RESET}"
                ;;
        esac
        sleep 0.5
    done
}

# ── Modalità non interattiva (argomenti CLI) ─────────────
# Uso: sudo ./fanctl.sh auto [fan]
#      sudo ./fanctl.sh set <fan> <pct>
#      sudo ./fanctl.sh status
if [[ $# -gt 0 ]]; then
    case "$1" in
        status)
            show_status ;;
        auto)
            fan="${2:-all}"
            if [[ "$fan" == "all" ]]; then
                for i in 1 2 3; do [[ -e "$HWMON/pwm${i}_enable" ]] && set_mode "$i" "auto"; done
            else
                set_mode "$fan" "auto"
            fi ;;
        set)
            # sudo ./fanctl.sh set <fan> <pct>
            [[ -z "$2" || -z "$3" ]] && echo "Uso: sudo $0 set <fan> <pct>" && exit 1
            set_speed "$2" "$3" ;;
        *)
            echo "Uso: sudo $0 [status|auto [fan]|set <fan> <pct>]"
            exit 1 ;;
    esac
    exit 0
fi

# Nessun argomento → menu interattivo
menu
