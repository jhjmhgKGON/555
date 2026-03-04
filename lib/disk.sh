#!/usr/bin/env bash
set -Eeuo pipefail

# ==========================================
# Logging
# ==========================================

log() {
    echo "[INFO] $*"
}

error() {
    echo "[ERROR] $*" >&2
    exit 1
}

# ==========================================
# Retry helper
# ==========================================

retry() {
    local attempts=5
    local count=0

    until "$@"; do
        ((count++))
        if ((count >= attempts)); then
            error "Command failed after $attempts attempts: $*"
        fi
        log "Retrying command..."
        sleep 2
    done
}

# ==========================================
# Disk validation
# ==========================================

disk_validate() {

    DISK="$1"

    [[ -b "$DISK" ]] || error "Invalid disk device: $DISK"

    if mount | grep -q "$DISK"; then
        error "Disk already mounted"
    fi

    log "Disk validated: $DISK"
}

# ==========================================
# Partition disk
# ==========================================

disk_partition() {

    log "Wiping disk"

    retry wipefs -af "$DISK"

    retry parted -s "$DISK" mklabel gpt

    log "Creating boot partition"

    retry parted -s "$DISK" mkpart ESP fat32 1MiB 513MiB
    retry parted -s "$DISK" set 1 esp on

    log "Creating root partition"

    retry parted -s "$DISK" mkpart primary ext4 513MiB 100%

    sleep 2
    partprobe "$DISK"
    udevadm settle

    detect_partitions
}

# ==========================================
# Detect partitions safely
# ==========================================

detect_partitions() {

    BOOT_PART=""
    ROOT_PART=""

    if [[ "$DISK" == *"nvme"* ]] || [[ "$DISK" == *"mmcblk"* ]]; then
        BOOT_PART="${DISK}p1"
        ROOT_PART="${DISK}p2"
    else
        BOOT_PART="${DISK}1"
        ROOT_PART="${DISK}2"
    fi

    [[ -b "$BOOT_PART" ]] || error "Boot partition not found"
    [[ -b "$ROOT_PART" ]] || error "Root partition not found"

    export BOOT_PART ROOT_PART

    log "Boot partition: $BOOT_PART"
    log "Root partition: $ROOT_PART"
}

# ==========================================
# Format partitions
# ==========================================

disk_format() {

    log "Formatting boot partition"

    retry mkfs.fat -F32 "$BOOT_PART"

    log "Formatting root partition"

    retry mkfs.ext4 -F "$ROOT_PART"
}

# ==========================================
# Mount partitions
# ==========================================

disk_mount() {

    log "Mounting root"

    retry mount "$ROOT_PART" /mnt

    mkdir -p /mnt/boot

    log "Mounting boot"

    retry mount "$BOOT_PART" /mnt/boot

    log "Mount successful"
}
