#!/usr/bin/env bash
set -euo pipefail

if [ "${EUID}" -ne 0 ]; then
  echo "Please run as root" >&2
  exit 1
fi

ZRAM_DEV="${ZRAM_DEV:-/dev/zram0}"
if [ ! -b "${ZRAM_DEV}" ]; then
  echo "ZRAM device ${ZRAM_DEV} not found" >&2
  exit 1
fi

ZRAM_SYS="/sys/block/$(basename "${ZRAM_DEV}")"

echo "Setting vm.swappiness=10" >&2
sysctl -w vm.swappiness=10 >/dev/null

echo "Resizing ${ZRAM_DEV} to 25% of RAM with lz4" >&2
swapoff "${ZRAM_DEV}" 2>/dev/null || true
echo lz4 > "${ZRAM_SYS}/comp_algorithm" || true
echo 1 > "${ZRAM_SYS}/reset"
SIZE=$(awk '/MemTotal/ {printf "%d", ($2*1024*25/100)}' /proc/meminfo)
echo "${SIZE}" > "${ZRAM_SYS}/disksize"
mkswap "${ZRAM_DEV}" >/dev/null
swapon -p 100 "${ZRAM_DEV}"

echo "zram gaming profile applied (swappiness=10, 25%)." >&2

