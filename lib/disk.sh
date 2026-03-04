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
    for disk in $(lsblk -d -n -o NAME | grep -v -E "loop|sr|rom"); do
        local size=$(lsblk -d -n -o SIZE "/dev/$disk" | tr -d ' ')
        local model=$(lsblk -d -n -o MODEL "/dev/$disk" | sed 's/^[ \t]*//;s/[ \t]*$//')
        echo "$disk $size $model"
    done
}

disk_select() {

    local options=()

    while read -r name size model; do
        options+=("$name" "$size $model")
    done < <(lsblk -d -o NAME,SIZE,MODEL -n | grep -v -E "loop|sr|rom")

    if [ ${#options[@]} -eq 0 ]; then
        whiptail --msgbox "No valid disks found!" 8 60
        exit 1
    fi

    local selected=$(whiptail \
        --title "💿 DISK SELECTION" \
        --menu "Select target disk:" \
        20 70 10 \
        "${options[@]}" \
        3>&1 1>&2 2>&3)

    if [ -n "$selected" ]; then
        disk=$(echo "$selected" | awk '{print $1}')
        echo "/dev/$disk"
    else
        echo ""
    fi
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
    local DISK="$1"
    ui_progress 15 "Creating partitions..."

    if [ -d /sys/firmware/efi ]; then
        # =========================
        # UEFI (GPT)
        # =========================
        execute parted -s "$DISK" mklabel gpt

        case "$ENCRYPTION" in
            luks2)
                # create partitions
                execute parted -s "$DISK" mkpart ESP fat32 1MiB 513MiB
                execute parted -s "$DISK" set 1 esp on
                execute parted -s "$DISK" mkpart primary 513MiB 100%

                # define partition variables
                BOOT_PART=$(get_partition "$DISK" 1)
                ROOT_PART=$(get_partition "$DISK" 2)
                LVM_PART=""
                ;;
            luks2+lvm)
                # create partitions
                execute parted -s "$DISK" mkpart ESP fat32 1MiB 513MiB
                execute parted -s "$DISK" set 1 esp on
                execute parted -s "$DISK" mkpart primary 513MiB 100%
                execute parted -s "$DISK" set 2 lvm on

                # define partition variables
                BOOT_PART=$(get_partition "$DISK" 1)
                LVM_PART=$(get_partition "$DISK" 2)
                ROOT_PART=""
                ;;
            *)
                # create partitions
                execute parted -s "$DISK" mkpart ESP fat32 1MiB 513MiB
                execute parted -s "$DISK" set 1 esp on
                execute parted -s "$DISK" mkpart primary ext4 513MiB 100%

                # define partition variables
                BOOT_PART=$(get_partition "$DISK" 1)
                ROOT_PART=$(get_partition "$DISK" 2)
                LVM_PART=""
                ;;
        esac

    else
        # =========================
        # BIOS (MBR)
        # =========================
        execute parted -s "$DISK" mklabel msdos

        case "$ENCRYPTION" in
            luks2|luks2+lvm)
                # create partitions
                execute parted -s "$DISK" mkpart primary 1MiB 100%
                execute parted -s "$DISK" set 1 boot on

                # define partition variables
                LVM_PART=$(get_partition "$DISK" 1)
                ROOT_PART=""
                ;;
            *)
                # create partitions
                execute parted -s "$DISK" mkpart primary ext4 1MiB 100%
                execute parted -s "$DISK" set 1 boot on

                # define partition variables
                ROOT_PART=$(get_partition "$DISK" 1)
                LVM_PART=""
                ;;
        esac
    fi

    execute partprobe "$DISK" || true
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
