#!/bin/bash
# UI functions - whiptail menus, progress bars

ui_show_banner() {
    whiptail --title "⚖️ KIRA ARCH INSTALLER ⚖️" --msgbox "
    ╔════════════════════════════════════════════════════╗
    ║                                                    ║
    ║     LIGHT YAGAMI'S ARCH LINUX INSTALLER           ║
    ║     \"I'll take a potato chip... and INSTALL!\"    ║
    ║                                                    ║
    ║     Version: $VERSION                             ║
    ║     Mode: $([ "$DRY_RUN" = "true" ] && echo "DRY RUN" || echo "LIVE")        ║
    ║                                                    ║
    ╚════════════════════════════════════════════════════╝
    
    Continue?" 20 70
}

ui_menu() {
    local title="$1"
    shift
    whiptail --title "$title" --menu "Choose:" 18 60 6 "$@" 3>&1 1>&2 2>&3
}

ui_input() {
    local prompt="$1"
    local default="$2"
    whiptail --inputbox "$prompt" 8 60 "$default" 3>&1 1>&2 2>&3
}

ui_yesno() {
    whiptail --yesno "$1" 10 60
}

ui_progress() {
    echo "$1" | whiptail --gauge "$2" 6 60 0
}

ui_progress_pipe() {
    whiptail --title "$1" --gauge "Starting..." 6 60 0
}

ui_optimize_mirrors() {
    log "INFO" "Optimizing mirrors..."
    ui_progress 5 "Optimizing mirrors..."
    
    if ! command -v reflector &>/dev/null; then
        log "WARNING" "reflector not found, skipping mirror optimization"
        return 1
    fi
    
    local country="${MIRROR_COUNTRY:-}"
    if [ -z "$country" ]; then
        country=$(curl -s --max-time 5 http://ip-api.com/line?fields=countryCode 2>/dev/null || echo "")
    fi
    
    if [ -n "$country" ]; then
        execute reflector \
            --country "$country" \
            --latest 10 \
            --protocol https \
            --sort rate \
            --download-timeout 20 \
            --save /etc/pacman.d/mirrorlist \
            || log "WARNING" "reflector failed, using default mirrorlist"
    else
        execute reflector \
            --latest 10 \
            --protocol https \
            --sort rate \
            --download-timeout 20 \
            --save /etc/pacman.d/mirrorlist \
            || log "WARNING" "reflector failed, using default mirrorlist"
    fi
    
    ui_progress 10 "Mirrors optimized"
}

ui_confirm_installation() {
    local summary="Ready to install:\n\n"
    summary+="Mode: $INSTALL_MODE\nDisk: $SELECTED_DISK\n"
    summary+="Encryption: $ENCRYPTION\nCPU: ${MICROCODE:-none}\n"
    summary+="GPU: ${GPU_DRIVERS[*]:-mesa}\nHostname: $HOSTNAME\nUser: $USERNAME\n\n"
    
    if [ "$DRY_RUN" = "true" ]; then
        summary+="⚠️ DRY RUN - No changes will be made\n\n"
    fi
    
    ui_yesno "$summary\nContinue?"
}

ui_dry_run_message() {
    whiptail --msgbox "DRY RUN - Commands would execute now.\nCheck the log: $LOG_FILE" 10 60
}

ui_finish() {
    whiptail --title "✅ INSTALLATION COMPLETE" --msgbox \
        "Arch Linux installed successfully!\n\nLog: $LOG_FILE\n\nRemove media and reboot." 15 60
    
    if ui_yesno "Reboot now?"; then
        reboot
    fi
}

ui_show_help() {
    cat << EOF
Kira Arch Installer v$VERSION

Usage: $0 [OPTIONS]

Options:
    --dry-run           Simulate installation
    --preseed FILE      Load preseed configuration
    --help              Show this help

Preseed variables:
    INSTALL_MODE        single|dual|usb
    SELECTED_DISK       /dev/sda
    ENCRYPTION          none|luks2|luks2+lvm
    HOSTNAME            system name
    USERNAME            username
    CRYPT_PASS          encryption password (AUTO mode)
    USERPASS            user password (AUTO mode)
    MIRROR_COUNTRY      US, DE, FR, etc.
    SWAP_SIZE           8G, 16G, etc.
    ROOT_SIZE           30G, 15G, etc.
    AUTO                true (skip all prompts)
    NO_BANNER           true (skip banner)
    NO_CONFIRM          true (skip disk confirmation)
EOF
}
