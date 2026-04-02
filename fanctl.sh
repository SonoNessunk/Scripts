#!/usr/bin/env bash
# fanctl.sh — Controllo ventole per hwmon3/device
# Uso: sudo ./fanctl.sh

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

read_sysfs() {
    local path="$1"
    [[ -r "$path" ]] && cat "$path" 2>/dev/null || echo "N/A"
}

pwm_to_pct() {
    local pwm="$1"
    [[ "$pwm" == "N/A" ]] && echo "N/A" && return
    echo $(( pwm * 100 / 255 ))
}

pct_to_pwm() {
    local pct="$1"
    echo $(( pct * 255 / 100 ))
}

enable_label() {
    case "$1" in
        0) echo -e "${RED}OFF${RESET}" ;;
        1) echo -e "${YELLOW}MANUALE${RESET}" ;;
        2) echo -e "${GREEN}AUTO${RESET}" ;;
        *) echo "N/A" ;;
    esac
}

# ── Layout ───────────────────────────────────────────────
FAN_ROW_OFFSET=3
FAN_BLOCK=5   # righe per ventola (blank + nome + modalità + pwm + rpm)

FANS=()
for _i in 1 2 3; do
    [[ -e "$HWMON/pwm${_i}" ]] && FANS+=("$_i")
done

fan_base_row() {
    echo $(( FAN_ROW_OFFSET + $1 * FAN_BLOCK ))
}

menu_row() {
    echo $(( FAN_ROW_OFFSET + ${#FANS[@]} * FAN_BLOCK + 1 ))
}

# ── Disegna valori di una ventola ────────────────────────
draw_fan_values() {
    local slot="$1" fan="$2"
    local base
    base=$(fan_base_row "$slot")

    local pwm_val enable_val rpm pct mode
    pwm_val=$(read_sysfs "$HWMON/pwm${fan}")
    enable_val=$(read_sysfs "$HWMON/pwm${fan}_enable")
    rpm=$(read_sysfs "$HWMON/fan${fan}_input")
    pct=$(pwm_to_pct "$pwm_val")
    mode=$(enable_label "$enable_val")

    # tput cup ROW COL  — sposta cursore alla riga ROW, colonna COL
    # tput el           — cancella dal cursore a fine riga (evita residui)
    tput cup $(( base + 1 )) 0; tput el; echo -e "  ${BOLD}Ventola ${fan}${RESET}"
    tput cup $(( base + 2 )) 0; tput el; echo -e "    Modalità : $mode"
    tput cup $(( base + 3 )) 0; tput el; echo -e "    PWM      : ${pwm_val}/255 (${pct}%)"
    tput cup $(( base + 4 )) 0; tput el; echo -e "    RPM      : ${rpm} giri/min"
}

# ── Disegna struttura fissa ──────────────────────────────
draw_static() {
    clear
    tput cup 0 0; echo -e "${BOLD}${CYAN}══════════════════════════════${RESET}"
    tput cup 1 0; echo -e "${BOLD}  Stato ventole  [live, 1s]${RESET}"
    tput cup 2 0; echo -e "${BOLD}${CYAN}══════════════════════════════${RESET}"

    local slot=0
    for fan in "${FANS[@]}"; do
        local base
        base=$(fan_base_row "$slot")
        tput cup $base 0; echo ""
        draw_fan_values "$slot" "$fan"
        (( slot++ ))
    done

    local mr
    mr=$(menu_row)
    tput cup $mr 0
    echo -e "${BOLD}${CYAN}══════════════════════════════${RESET}"
    echo ""
    echo -e "${BOLD}Cosa vuoi fare?${RESET}"
    echo "  1) Metti una ventola in AUTO"
    echo "  2) Metti una ventola in MANUALE + imposta velocità"
    echo "  3) Imposta velocità (ventola già in manuale)"
    echo "  4) Metti TUTTE in AUTO"
    echo "  5) Metti TUTTE al 100% (manuale)"
    echo "  q) Esci"
    echo ""
}

# ── Background job: aggiorna valori ogni secondo ─────────
LIVE_PID=""

start_live() {
    (
        while true; do
            local slot=0
            for fan in "${FANS[@]}"; do
                draw_fan_values "$slot" "$fan"
                (( slot++ ))
            done
            tput cup $(( $(menu_row) + 9 )) 0
            sleep 1
        done
    ) &
    LIVE_PID=$!
}

stop_live() {
    if [[ -n "$LIVE_PID" ]]; then
        kill "$LIVE_PID" 2>/dev/null
        wait "$LIVE_PID" 2>/dev/null
        LIVE_PID=""
    fi
}

goto_input() {
    tput cup $(( $(menu_row) + 9 )) 0
}

# ── Imposta modalità ─────────────────────────────────────
set_mode() {
    local fan="$1" mode="$2"
    local enable_path="$HWMON/pwm${fan}_enable"

    [[ ! -e "$enable_path" ]] && return 1
    [[ ! -w "$enable_path" ]] && return 1

    local val
    [[ "$mode" == "auto" ]] && val=2 || val=1

    if ! echo "$val" > "$enable_path" 2>/dev/null; then
        echo "0" > "$enable_path" 2>/dev/null || true
    fi
}

# ── Imposta velocità ─────────────────────────────────────
set_speed() {
    local fan="$1" pct="$2"
    local pwm_path="$HWMON/pwm${fan}"
    local enable_path="$HWMON/pwm${fan}_enable"

    [[ ! -e "$pwm_path" ]] && return 1
    [[ ! -w "$pwm_path" ]] && return 1

    echo "1" > "$enable_path" 2>/dev/null || true

    local pwm_val
    pwm_val=$(pct_to_pwm "$pct")
    (( pwm_val < 0 ))   && pwm_val=0
    (( pwm_val > 255 )) && pwm_val=255

    echo "$pwm_val" > "$pwm_path"
}

# ── Menu interattivo ─────────────────────────────────────
menu() {
    draw_static
    start_live

    trap 'stop_live; tput cnorm; echo ""; exit 0' INT TERM

    while true; do
        goto_input
        read -rp "Scelta: " choice

        stop_live

        case "$choice" in
            1)
                goto_input; read -rp "  Numero ventola (${FANS[*]}): " fn
                set_mode "$fn" "auto"
                ;;
            2)
                goto_input; read -rp "  Numero ventola (${FANS[*]}): " fn
                goto_input; read -rp "  Velocità % (0-100): " sp
                set_speed "$fn" "$sp"
                ;;
            3)
                goto_input; read -rp "  Numero ventola (${FANS[*]}): " fn
                goto_input; read -rp "  Velocità % (0-100): " sp
                set_speed "$fn" "$sp"
                ;;
            4)
                for fan in "${FANS[@]}"; do set_mode "$fan" "auto"; done
                ;;
            5)
                for fan in "${FANS[@]}"; do set_speed "$fan" 100; done
                ;;
            q|Q)
                stop_live
                clear
                echo -e "${GREEN}Uscito.${RESET}"
                exit 0
                ;;
            *)
                goto_input
                echo -e "${RED}  Scelta non valida.${RESET}"
                sleep 0.8
                ;;
        esac

        draw_static
        start_live
    done
}

# ── Modalità non interattiva (argomenti CLI) ─────────────
if [[ $# -gt 0 ]]; then
    case "$1" in
        status)
            for fan in "${FANS[@]}"; do
                echo "Ventola $fan: PWM=$(read_sysfs "$HWMON/pwm${fan}") RPM=$(read_sysfs "$HWMON/fan${fan}_input")"
            done ;;
        auto)
            fan="${2:-all}"
            if [[ "$fan" == "all" ]]; then
                for f in "${FANS[@]}"; do set_mode "$f" "auto"; done
            else
                set_mode "$fan" "auto"
            fi ;;
        set)
            [[ -z "$2" || -z "$3" ]] && echo "Uso: sudo $0 set <fan> <pct>" && exit 1
            set_speed "$2" "$3" ;;
        *)
            echo "Uso: sudo $0 [status|auto [fan]|set <fan> <pct>]"
            exit 1 ;;
    esac
    exit 0
fi

menu
