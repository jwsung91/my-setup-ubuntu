#!/bin/bash

if [[ -z "${MY_SETUP_UI_LOADED:-}" ]]; then
    MY_SETUP_UI_LOADED=1

    supports_color() {
        [[ -t 1 ]] && [[ -z "${NO_COLOR:-}" ]] && [[ "${TERM:-}" != "dumb" ]]
    }

    init_ui_colors() {
        if supports_color; then
            UI_RESET=$'\033[0m'
            UI_BOLD=$'\033[1m'
            UI_BLUE=$'\033[34m'
            UI_CYAN=$'\033[36m'
            UI_GREEN=$'\033[32m'
            UI_YELLOW=$'\033[33m'
            UI_RED=$'\033[31m'
        else
            UI_RESET=""
            UI_BOLD=""
            UI_BLUE=""
            UI_CYAN=""
            UI_GREEN=""
            UI_YELLOW=""
            UI_RED=""
        fi
    }

    log_line() {
        local level="$1"
        local color="$2"
        shift 2

        printf '%b[%s]%b %s\n' "${color}${UI_BOLD}" "$level" "$UI_RESET" "$*"
    }

    log_info() {
        log_line "INFO" "$UI_CYAN" "$@"
    }

    log_ok() {
        log_line "OK" "$UI_GREEN" "$@"
    }

    log_warn() {
        log_line "WARN" "$UI_YELLOW" "$@"
    }

    log_ask() {
        printf '%b[?]%b %s' "${UI_CYAN}${UI_BOLD}" "$UI_RESET" "$*"
    }

    log_error() {
        printf '%b[ERROR]%b %s\n' "${UI_RED}${UI_BOLD}" "$UI_RESET" "$*" >&2
    }

    log_section() {
        printf '%b== %s ==%b\n' "${UI_BLUE}${UI_BOLD}" "$*" "$UI_RESET"
    }

    log_status() {
        local status="$1"
        local level="$2"
        shift 2

        local color="$UI_CYAN"
        case "$status" in
            OK) color="$UI_GREEN" ;;
            WARN) color="$UI_YELLOW" ;;
            ERROR) color="$UI_RED" ;;
            INFO) color="$UI_CYAN" ;;
        esac

        printf '%b[%s]%b[%s] %s\n' "${color}${UI_BOLD}" "$status" "$UI_RESET" "$level" "$*"
    }

    configure_whiptail_colors() {
        export NEWT_COLORS='
root=,black
window=white,black
border=blue,black
title=cyan,black
textbox=white,black
checkbox=white,black
actcheckbox=black,yellow
button=black,blue
actbutton=white,blue
entry=white,black
'
    }

    init_ui_colors
fi
