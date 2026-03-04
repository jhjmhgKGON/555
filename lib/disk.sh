#!/bin/bash
# Disk operations - detection, partitioning, mounting

# ======================================================================
# HELPER FUNCTIONS - NVMe SUPPORT
# ======================================================================

get_partition() {
    local disk="$1"
    local part_num="$2"
    
    if [[ "$disk" =~ nvme[0-9]+n[0-9]+$ ]]; then
        echo "${disk}p${part_num}"
    elif [[ "$disk" =~ /dev/[a-z]+$ ]] || [[ "$disk" =~ /dev/[a-z]+[a-z]+$ ]]; then
        echo "${disk}${part_num}"
    else
        echo "${disk}${part_num}"
    fi
}

# ======================================================================
# DISK DETECTION
# ======================================================================

disk_get_valid() {
    lsblk -d -o NAME,SIZE,MODEL -n | grep -v -E "loop|sr|rom" | awk '{print $1 " " $2 " " $3}'
}

disk_select() {
    while true; do
        local disks=$(disk_get_valid)
        if [ -z "$disks" ]; then
            whiptail --msgbox "No valid disks found!" 8 60
            exit 1
        fi
        
        local disk_array=()
        while IFS= read -r line; do
            disk_array+=($line)
        done <<< "$disks"
        
        local selected=$(whiptail --title "💿 DISK SELECTION" --menu \
            "Select target disk:" 20 70 10 "${disk_array[@]}" 3>&1 1>&2 2>&3)
        if [ -n "$selected" ]; then
            echo "/dev/$selected"
            break
        fi
    done
}

# ======================================================================
# DISK VALIDATION
# ======================================================================

disk_validate() {
    local disk="$1"
    if [ ! -b "$disk" ]; then
        log "ERROR" "Invalid disk: $disk"
        return 1
    fi
    
    local mounted=$(lsblk -nr -o MOUNTPOINT "$disk" | grep -c '[^[:space:]]')
    if [ "$mounted" -gt 0 ]; then
        log "ERROR" "Disk $disk has mounted partitions:"
        lsblk "$disk" -o NAME,MOUNTPOINT | grep -v '^$' | while read line; do
            log "ERROR" "  $line"
        done
        return 1
    fi
    
    log "INFO" "Disk validation passed: $disk"
    return 0
}

disk_confirm() {
    local disk="$1"
    local model=$(lsblk -d -o MODEL "$disk" | tail -1 | xargs)
    local info=$(lsblk -d -o NAME,SIZE,MODEL,SERIAL "$disk" | tail -1)
    
    whiptail --title "⚠️ CONFIRMATION ⚠️" --yesno \
        "Disk: $disk\nModel: $model\n$info\n\nALL DATA WILL BE DESTROYED\n\nType model to confirm:" 15 70
    
    local confirm=$(whiptail --inputbox "Type disk model:\n($model)" 10 60 3>&1 1>&2 2>&3)
    if [ "$confirm" = "$model" ]; then
        return 0
    else
        whiptail --msgbox "❌ Mismatch! Aborting." 8 60
        return 1
    fi
}

# ======================================================================
# GET DISK SIZE
# ======================================================================

get_disk_size_gb() {
    local disk="$1"
    local size_bytes=$(lsblk -b -d -o SIZE "$disk" | tail -1)
    echo $((size_bytes / 1024 / 1024 / 1024))
}

# ======================================================================
# PARTITIONING
# ======================================================================

disk_create_partitions() {
    local disk="$1"
    ui_progress 15 "Creating partitions..."

    local efi_start="1MiB"
    local efi_end="513MiB"
    local root_start="$efi_end"
    local root_end="100%"

    if [ -d /sys/firmware/efi ]; then
        # =========================
        # UEFI (GPT)
        # =========================
        execute parted -s "$disk" mklabel gpt

        # EFI Partition
        execute parted -s "$disk" mkpart primary fat32 "$efi_start" "$efi_end"
        execute parted -s "$disk" set 1 esp on

        BOOT_PART=$(get_partition "$disk" 1)

        case "$ENCRYPTION" in
            luks2)
                execute parted -s "$disk" mkpart primary "$root_start" "$root_end"
                ROOT_PART=$(get_partition "$disk" 2)
                LVM_PART=""
                ;;
            luks2+lvm)
                execute parted -s "$disk" mkpart primary "$root_start" "$root_end"
                execute parted -s "$disk" set 2 lvm on
                LVM_PART=$(get_partition "$disk" 2)
                ROOT_PART=""
                ;;
            *)
                execute parted -s "$disk" mkpart primary ext4 "$root_start" "$root_end"
                ROOT_PART=$(get_partition "$disk" 2)
                LVM_PART=""
                ;;
        esac

    else
        # =========================
        # BIOS (MBR)
        # =========================
        execute parted -s "$disk" mklabel msdos

        case "$ENCRYPTION" in
            luks2|luks2+lvm)
                execute parted -s "$disk" mkpart primary 1MiB 100%
                execute parted -s "$disk" set 1 boot on
                LVM_PART=$(get_partition "$disk" 1)
                ROOT_PART=""
                ;;
            *)
                execute parted -s "$disk" mkpart primary ext4 1MiB 100%
                execute parted -s "$disk" set 1 boot on
                ROOT_PART=$(get_partition "$disk" 1)
                LVM_PART=""
                ;;
        esac
    fi

    execute partprobe "$disk" || true
    udevadm settle || true

    log "INFO" "Partitions created:"
    log "INFO" "  BOOT=$BOOT_PART"
    log "INFO" "  ROOT=$ROOT_PART"
    log "INFO" "  LVM=$LVM_PART"

    export BOOT_PART ROOT_PART LVM_PART
}

# ======================================================================
# MOUNTING
# ======================================================================

disk_mount_partitions() {
    ui_progress 30 "Mounting partitions..."
    if [ -n "${ROOT_MAPPER:-}" ]; then
        execute mount "$ROOT_MAPPER" /mnt
    fi
    if [ -n "${BOOT_PART:-}" ]; then
        execute mkdir -p /mnt/boot
        execute mount "$BOOT_PART" /mnt/boot
    fi
    if [ -n "${HOME_MAPPER:-}" ]; then
        execute mkdir -p /mnt/home
        execute mount "$HOME_MAPPER" /mnt/home
    fi
}

# ======================================================================
# CLEANUP
# ======================================================================

disk_unmount_cleanup() {
    log "INFO" "Cleaning up..."
    sync
    
    umount -R /mnt 2>/dev/null || true
    
    if [ -e /dev/mapper/cryptlvm ]; then
        swapoff -a 2>/dev/null || true
        cryptsetup close cryptlvm 2>/dev/null || true
    fi
    
    if [ -e /dev/mapper/cryptroot ]; then
        cryptsetup close cryptroot 2>/dev/null || true
    fi
    
    vgchange -an 2>/dev/null || true
    log "INFO" "Cleanup complete"
}
