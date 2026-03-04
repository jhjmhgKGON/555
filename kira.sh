#!/bin/bash
# Kira Arch Installer - Main Entry Point
# Version: 15.0.0-KIRA-FINAL
# "I'll take a potato chip... and INSTALL ARCH LINUX!" - Light Yagami

# ======================================================================
# STRICT MODE WITH SUBSHELL TRACING
# ======================================================================
set -euo pipefail
set -o errtrace
IFS=$'\n\t'

# ======================================================================
# COMMAND VALIDATION (with fallbacks)
# ======================================================================
REQUIRED_COMMANDS=(
    "parted" "cryptsetup" "reflector" "pacstrap" "arch-chroot"
    "genfstab" "mkfs.fat" "mkfs.ext4" "blkid" "lsblk" "curl"
    "swapoff" "vgchange" "partprobe" "lspci"
)

for cmd in "${REQUIRED_COMMANDS[@]}"; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "ERROR: Required command not found: $cmd"
        echo "Please install: $cmd"
        exit 1
    fi
done

# ======================================================================
# SOURCE MODULES
# ======================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
for module in common ui disk encryption system bootloader; do
    if [ ! -f "$SCRIPT_DIR/lib/${module}.sh" ]; then
        echo "ERROR: Module not found: lib/${module}.sh"
        exit 1
    fi
    source "$SCRIPT_DIR/lib/${module}.sh"
done

# ======================================================================
# CONFIGURATION
# ======================================================================
VERSION="15.0.0-KIRA-FINAL"
LOG_FILE="/var/log/kira-installer-$(date +%Y%m%d-%H%M%S).log"
CONFIG_DIR="/etc/kira-installer"
STATE_DIR="/tmp/kira-state"
PRESEED_FILE="/etc/kira-installer/preseed.conf"
DRY_RUN=${DRY_RUN:-false}

mkdir -p "$CONFIG_DIR" "$STATE_DIR"

# ======================================================================
# INITIALIZATION
# ======================================================================
exec > >(tee -a "$LOG_FILE") 2>&1

cleanup_on_exit() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        log "ERROR" "Installation failed with code $exit_code! Cleaning up..."
        disk_unmount_cleanup
    else
        log "INFO" "Installation completed successfully"
    fi
}
trap cleanup_on_exit EXIT

export VERSION LOG_FILE STATE_DIR DRY_RUN

# ======================================================================
# PRESEED LOADING
# ======================================================================
load_preseed() {
    if [ -f "$PRESEED_FILE" ]; then
        log "INFO" "Loading preseed from $PRESEED_FILE"
        source "$PRESEED_FILE"
        
        INSTALL_MODE="${INSTALL_MODE:-single}"
        ENCRYPTION="${ENCRYPTION:-none}"
        HOSTNAME="${HOSTNAME:-kira-arch}"
        
        export INSTALL_MODE ENCRYPTION HOSTNAME USERNAME
        [ -n "${SELECTED_DISK:-}" ] && export SELECTED_DISK
        [ -n "${CRYPT_PASS:-}" ] && export CRYPT_PASS
        [ -n "${USERPASS:-}" ] && export USERPASS
        [ -n "${MIRROR_COUNTRY:-}" ] && export MIRROR_COUNTRY
        [ -n "${SWAP_SIZE:-}" ] && export SWAP_SIZE
        [ -n "${ROOT_SIZE:-}" ] && export ROOT_SIZE
        
        log "INFO" "Preseed loaded: Mode=$INSTALL_MODE, Disk=${SELECTED_DISK:-auto}, Encryption=$ENCRYPTION"
        return 0
    fi
    return 1
}

# ======================================================================
# VALIDATION FUNCTIONS
# ======================================================================
validate_encryption_value() {
    case "$1" in none|luks2|luks2+lvm) return 0 ;; *)
        log "ERROR" "Invalid ENCRYPTION: $1 (must be none, luks2, or luks2+lvm)"
        return 1 ;;
    esac
}

validate_required_vars() {
    local missing=0
    [ -z "${USERNAME:-}" ] && log "ERROR" "USERNAME required" && missing=1
    [ -z "${HOSTNAME:-}" ] && log "ERROR" "HOSTNAME required" && missing=1
    [ -z "${INSTALL_MODE:-}" ] && log "ERROR" "INSTALL_MODE required" && missing=1
    validate_encryption_value "$ENCRYPTION" || missing=1
    
    if [ "$ENCRYPTION" != "none" ] && [ -z "${CRYPT_PASS:-}" ] && [ "$AUTO" = "true" ]; then
        log "ERROR" "Encryption enabled but CRYPT_PASS not set in preseed (AUTO mode)"
        missing=1
    fi
    
    if [ -z "${USERPASS:-}" ] && [ "$AUTO" = "true" ]; then
        log "ERROR" "USERPASS not set in preseed (AUTO mode)"
        missing=1
    fi
    return $missing
}

# ======================================================================
# NETWORK TEST
# ======================================================================
test_network() {
    log "INFO" "Testing network connectivity..."
    
    if command -v ping &>/dev/null; then
        if ping -c 1 archlinux.org &>/dev/null; then
            log "INFO" "Network connectivity confirmed"
            return 0
        fi
    fi
    
    if curl -s --max-time 5 http://archlinux.org >/dev/null; then
        log "INFO" "Network connectivity confirmed via curl"
        return 0
    fi
    
    log "WARNING" "No internet connection detected. Installation may fail."
    return 1
}

# ======================================================================
# MAIN INSTALLATION FLOW
# ======================================================================
main() {
    local preseed_loaded=false
    load_preseed && preseed_loaded=true
    
    if [ "${NO_BANNER:-false}" != "true" ]; then
        ui_show_banner || exit 1
    fi
    
    test_network
    
    if [ -z "${INSTALL_MODE:-}" ]; then
        INSTALL_MODE=$(ui_menu "Installation Mode" \
            "single" "Single Boot - Clean install" \
            "dual" "Dual Boot - Alongside existing OS" \
            "usb" "USB - Portable installation") || exit 1
        export INSTALL_MODE
    fi
    log "INFO" "Installation mode: $INSTALL_MODE"
    
    ui_optimize_mirrors || log "WARNING" "Mirror optimization failed, using defaults"
    
    if [ -z "${SELECTED_DISK:-}" ]; then
        SELECTED_DISK=$(disk_select)
        export SELECTED_DISK
    else
        log "INFO" "Using preseed disk: $SELECTED_DISK"
    fi
    
    disk_validate "$SELECTED_DISK" || exit 1
    
    if [ "${NO_CONFIRM:-false}" != "true" ] && [ "${AUTO:-false}" != "true" ]; then
        disk_confirm "$SELECTED_DISK" || exit 1
    fi
    
    bootloader_detect_microcode
    system_detect_gpu
    
    if [ -z "${ENCRYPTION:-}" ]; then
        encryption_setup
    else
        log "INFO" "Using preseed encryption: $ENCRYPTION"
        if [ "$ENCRYPTION" != "none" ] && [ -z "${CRYPT_PASS:-}" ]; then
            get_password_confirm "Encryption passphrase" CRYPT_PASS
            export CRYPT_PASS
        fi
    fi
    
    [ -z "${HOSTNAME:-}" ] && HOSTNAME=$(ui_input "Hostname" "kira-arch") && export HOSTNAME
    [ -z "${USERNAME:-}" ] && USERNAME=$(ui_input "Username" "") && export USERNAME
    
    if [ -z "${USERPASS:-}" ]; then
        get_password_confirm "User password" USERPASS
        export USERPASS
    fi
    
    validate_required_vars || exit 1
    
    if [ "${AUTO:-false}" != "true" ]; then
        ui_confirm_installation || { clear_passwords; exit 0; }
    fi
    
    if [ "$DRY_RUN" = "true" ]; then
        ui_dry_run_message
        clear_passwords
        exit 0
    fi
    
    (
        ui_progress 10 "Creating partitions..."
        disk_create_partitions "$SELECTED_DISK"
        
        ui_progress 20 "Setting up encryption..."
        encryption_format
        
        ui_progress 30 "Mounting partitions..."
        disk_mount_partitions
        
        ui_progress 40 "Installing base system..."
        system_install_base
        
        ui_progress 50 "Generating fstab..."
        execute genfstab -U /mnt >> /mnt/etc/fstab
        
        ui_progress 60 "Configuring system..."
        system_configure
        
        ui_progress 70 "Installing bootloader..."
        bootloader_install
        
        ui_progress 90 "Finalizing installation..."
        clear_passwords
        ui_progress 100 "Installation complete!"
    ) 2>&1 | tee -a "$LOG_FILE" | ui_progress_pipe "Installation Progress"
    
    ui_finish
}

# ======================================================================
# START
# ======================================================================
if [ "$EUID" -ne 0 ]; then
    echo "Even Kira needs root privileges. Run with sudo."
    exit 1
fi

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run) DRY_RUN=true ;;
        --preseed) PRESEED_FILE="$2"; shift ;;
        --help) ui_show_help; exit 0 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
    shift
done

main
