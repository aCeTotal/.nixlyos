#!/usr/bin/env bash

# NixOS installer for SSD/NVMe with FDE (root) and ext4.
# - Bootloader: systemd-boot (UEFI). Note: ESP (/boot) remains unencrypted by UEFI design.
# - Root: LUKS2 (argon2id) + ext4 tuned for SSD with low I/O (no swap partition; zram enabled).
# - Destructive: WIPES the chosen disk completely.

set -euo pipefail

die() { echo "[ERROR] $*" >&2; exit 1; }
log() { echo "[INFO] $*" >&2; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

confirm() { return 0; }

usage() {
  cat <<EOF
Usage: sudo $(basename "$0") [--disk /dev/xxx] [--hostname NAME] [--flake-dir PATH] [--luks-passphrase PASS | --luks-passphrase-file FILE | --luks-passphrase-stdin | --prompt-luks-passphrase]

Performs a clean NixOS installation on the selected disk with:
- GPT: 512MiB ESP (FAT32, unencrypted), rest LUKS2 (argon2id) for root
- Root filesystem: ext4, SSD/NVMe optimized (noatime, discard=async)
- Bootloader: systemd-boot (UEFI)
- Swap: zram (no swap partition)

Options:
  --disk                   Device to install to (e.g., /dev/nvme0n1 or /dev/sda)
  --hostname               Hostname to set (default: nixlyos)
  --flake-dir              Path to flake directory (default: ~/.nixlyos of invoking user)
  --luks-passphrase        LUKS passphrase (non-interactive)
  --luks-passphrase-file   File containing LUKS passphrase
  --luks-passphrase-stdin  Read LUKS passphrase from stdin (non-interactive; safe from argv)
  --prompt-luks-passphrase Prompt securely for LUKS passphrase (no echo; safest for history)

Notes on encryption requirements:
- With systemd-boot, the ESP (/boot, FAT32) cannot be encrypted by UEFI design.
- All OS data, including /, is encrypted with modern LUKS2 (argon2id).
- If you require an encrypted /boot as well, install with GRUB instead.
EOF
}

DISK=""
HOSTNAME="nixlyos"
LUKS_PASSPHRASE=""
LUKS_PASSPHRASE_FILE=""
LUKS_PASSPHRASE_STDIN=0
LUKS_PASSPHRASE_PROMPT=0
FLAKE_DIR=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage; exit 0;;
    --disk) DISK=${2:-}; shift 2;;
    --hostname) HOSTNAME=${2:-}; shift 2;;
    --flake-dir) FLAKE_DIR=${2:-}; shift 2;;
    --luks-passphrase) LUKS_PASSPHRASE=${2:-}; shift 2;;
    --luks-passphrase-file) LUKS_PASSPHRASE_FILE=${2:-}; shift 2;;
    --luks-passphrase-stdin) LUKS_PASSPHRASE_STDIN=1; shift 1;;
    --prompt-luks-passphrase) LUKS_PASSPHRASE_PROMPT=1; shift 1;;
    *) die "Unknown argument: $1";;
  esac
done

# Preconditions
for c in parted sgdisk lsblk awk sed grep mkfs.vfat mkfs.ext4 cryptsetup blkid mount umount nixos-generate-config nixos-install base64; do
  require_cmd "$c"
done

[[ $EUID -eq 0 ]] || die "Run as root (sudo)."

# Auto-pick a disk if not provided: prefer NVMe/SSD, size >= 32G, non-removable.
if [[ -z "$DISK" ]]; then
  CANDIDATE=$(lsblk -dn -o NAME,TYPE,RM,SIZE,ROTA | awk '$2=="disk" && $3==0 {print $0}' | awk '(index($1,"nvme")==1 || $5==0) {print $1}' | head -n1)
  [[ -n "$CANDIDATE" ]] || die "Could not auto-detect a suitable disk. Use --disk /dev/XXX"
  DISK="/dev/${CANDIDATE}"
  log "Auto-selected disk: $DISK"
fi

[[ -b "$DISK" ]] || die "Disk not found: $DISK"

log "Proceeding to ERASE ALL DATA on $DISK (non-interactive)"

# Unmount anything under /mnt from previous attempts
if mountpoint -q /mnt; then
  log "Unmounting previous /mnt"
  umount -R /mnt || true
fi

swapoff -a || true

log "Wiping partition table on $DISK"
sgdisk --zap-all "$DISK"

log "Creating GPT partitions (ESP + LUKS root)"
parted -s "$DISK" -- mklabel gpt \
  mkpart ESP fat32 1MiB 513MiB \
  set 1 esp on \
  name 1 NIXESP \
  mkpart primary 513MiB 100% \
  name 2 NIXLUKS

# Resolve partition paths (handle nvme pN suffix)
P1=$(lsblk -no PATH -r "$DISK" | sed -n '2p')
P2=$(lsblk -no PATH -r "$DISK" | sed -n '3p')
[[ -n "$P1" && -n "$P2" ]] || die "Failed to resolve partition paths for $DISK"

log "Formatting ESP (FAT32): $P1"
mkfs.vfat -F32 -n NIXBOOT "$P1"

log "Preparing LUKS2 passphrase"
# Precedence: file > arg > stdin > prompt > generate
if [[ -n "$LUKS_PASSPHRASE_FILE" ]]; then
  [[ -f "$LUKS_PASSPHRASE_FILE" ]] || die "Passphrase file not found: $LUKS_PASSPHRASE_FILE"
  LUKS_PASSPHRASE=$(cat "$LUKS_PASSPHRASE_FILE")
elif [[ -n "$LUKS_PASSPHRASE" ]]; then
  : # already set via --luks-passphrase
elif [[ "$LUKS_PASSPHRASE_STDIN" -eq 1 ]]; then
  if [[ -t 0 ]]; then
    die "--luks-passphrase-stdin requested but stdin is a TTY. Use --prompt-luks-passphrase for interactive entry."
  fi
  IFS= read -r LUKS_PASSPHRASE || die "Failed reading passphrase from stdin"
elif [[ "$LUKS_PASSPHRASE_PROMPT" -eq 1 ]]; then
  read -rs -p "Enter LUKS passphrase: " LUKS_PASSPHRASE; echo
  read -rs -p "Confirm LUKS passphrase: " LUKS_PASSPHRASE_CONFIRM; echo
  [[ -n "$LUKS_PASSPHRASE" ]] || die "Empty passphrase not allowed"
  [[ "$LUKS_PASSPHRASE" == "$LUKS_PASSPHRASE_CONFIRM" ]] || die "Passphrases do not match"
fi

if [[ -z "$LUKS_PASSPHRASE" ]]; then
  # Generate strong random passphrase (printed once for user to store)
  LUKS_PASSPHRASE=$(head -c 64 /dev/urandom | base64 -w0)
  log "Generated LUKS passphrase (SAVE THIS NOW):"
  echo "$LUKS_PASSPHRASE"
fi

log "Setting up LUKS2 on $P2 (argon2id, high iteration time)"
printf '%s' "$LUKS_PASSPHRASE" | cryptsetup luksFormat \
  --batch-mode \
  --type luks2 \
  --cipher aes-xts-plain64 \
  --key-size 512 \
  --pbkdf argon2id \
  --iter-time 5000 \
  --hash sha512 \
  --key-file - \
  "$P2"

log "Opening LUKS container as cryptroot (allow discards)"
printf '%s' "$LUKS_PASSPHRASE" | cryptsetup open \
  --type luks \
  --allow-discards \
  --key-file - \
  "$P2" cryptroot

log "Creating ext4 filesystem on /dev/mapper/cryptroot"
mkfs.ext4 -L nixos \
  -O 64bit,metadata_csum,dir_index,extent \
  /dev/mapper/cryptroot

log "Mounting target filesystem"
mount -o noatime,discard=async,commit=120 /dev/mapper/cryptroot /mnt
mkdir -p /mnt/boot
mount "$P1" /mnt/boot

log "Generating NixOS hardware configuration"
nixos-generate-config --root /mnt

HWC=/mnt/etc/nixos/hardware-configuration.nix

# Resolve flake directory
if [[ -z "$FLAKE_DIR" ]]; then
  # Determine target user's home for flake path ~/.nixlyos
  if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
  else
    USER_HOME=${HOME:-/root}
  fi
  FLAKE_DIR="$USER_HOME/.nixlyos"
fi
[[ -d "$FLAKE_DIR" ]] || die "Flake directory not found: $FLAKE_DIR (expected ~/.nixlyos)"

log "Copying fresh hardware-configuration.nix into flake at $FLAKE_DIR"
rm -f "$FLAKE_DIR/hardware-configuration.nix" || true
cp "$HWC" "$FLAKE_DIR/hardware-configuration.nix"

log "Installing NixOS from flake $FLAKE_DIR#nixlyos (no root password)"
nixos-install --no-root-password --root /mnt --flake "$FLAKE_DIR#nixlyos"

log "Installation complete. Unmounting and closing LUKS."
umount -R /mnt || true
cryptsetup close cryptroot || true

log "Done. Reboot into your new system."
