#!/usr/bin/env bash
# Full oppdatering: bump stable-grena om ny NixOS-release finnes,
# bump proton-ge-pin, oppdater ALLE flake-inputs, bygg for neste boot.
set -euo pipefail

REPO="$HOME/.nixlyos"
FLAKE="$REPO/flake.nix"
. "$REPO/scripts/ui.sh"

# detect-hw.sh skriver genererte filer i repoet foer hver eval, saa treet er
# alltid dirty. nix.settings.warn-dirty i nix.nix gjelder foerst etter neste
# aktivering — env-varen slaar den av her og naa, ogsaa for barneprosessene
# (nix-prefetch-url i bump-scriptene, nixos-rebuild sin eval).
export NIX_CONFIG="warn-dirty = false"

# Passordet spoerres FOERST, ikke etter en halvtime med bygging. Bakgrunns-
# loopen holder sudo-timestampen varm saa `nixos-rebuild --sudo` til slutt
# ikke rekker aa timeoute (default 5 min).
ui_head "NixlyOS update"
sudo -v
while sudo -n true 2>/dev/null; do sleep 50; done &
sudo_keepalive=$!
trap 'kill "$sudo_keepalive" 2>/dev/null' EXIT

ui_head "Hardware"
# CPU/GPU-imports i modules/core/default.nix maa matche maskinen FOER eval.
bash "$REPO/scripts/detect-hw.sh" "$REPO"

cur=$(grep -oP 'nixpkgs/nixos-\K[0-9]{2}\.[0-9]{2}' "$FLAKE")

# 25.11 -> 26.05 -> 26.11 -> 27.05 ...
next_ver() {
  local y=${1%%.*} m=${1##*.}
  if [ "$m" = "05" ]; then echo "$y.11"; else printf '%02d.05\n' $((10#$y + 1)); fi
}

has_branch() { git ls-remote --exit-code --heads "$1" "$2" >/dev/null 2>&1; }

# Hopper bare til en ny release naar BEGGE grenene finnes — home-manager
# mot feil nixpkgs-base brekker evalueringen.
new=$cur
while cand=$(next_ver "$new") &&
      has_branch https://github.com/NixOS/nixpkgs "nixos-$cand" &&
      has_branch https://github.com/nix-community/home-manager "release-$cand"; do
  new=$cand
done

ui_head "Channel"
if [ "$new" != "$cur" ]; then
  ui_ok "Bumped channel from $cur to the newest: $new"
  sed -i "s|nixpkgs/nixos-$cur|nixpkgs/nixos-$new|; s|home-manager/release-$cur|home-manager/release-$new|" "$FLAKE"
else
  ui_ok "Using the latest stable-channel: $cur"
fi

ui_head "Proton-GE"
bash "$REPO/pkgs/proton-ge/bump.sh"

ui_head "nixlypkgs"
bash "$REPO/scripts/bump-nixlypkgs.sh"

ui_head "Flake inputs"
# Kopi av lock-fila FOER oppdateringen: retry-runden under trenger de gamle
# revisjonene for aa kunne rulle tilbake bare den kilden som feiler.
lockbak=$(mktemp -t nixlyos-lock.XXXXXX)
cp "$REPO/flake.lock" "$lockbak"

# Lock-diffen er stoey (to linjer med rev+narHash per input). Fanges opp og
# vises bare naar kommandoen feiler; ellers oppsummeres den.
if ! lockdiff=$(nix flake update --refresh --flake "$REPO" 2>&1); then
  printf '%s\n' "$lockdiff" >&2
  exit 1
fi
updated=$(grep -oP "^• Updated input '\K[^'/]+(?=')" <<<"$lockdiff" | tr '\n' ' ' || true)
[ -n "$updated" ] && ui_ok "updated: ${updated% }" || ui_ok "all inputs already current"

ui_head "Rebuild"
# switch foerst saa alt er brukbart med en gang; feiler aktiveringen, faller
# vi tilbake til boot (samme bygg, bare pinnet til neste oppstart). --keep-going
# bygger alt som KAN bygges selv om en avledning feiler. Output gaar til logg og
# vises bare naar ingenting til slutt gikk gjennom.
#
# --sudo, ikke `sudo nixos-rebuild`: evalueringen maa skje som bruker, ellers
# naar ikke fetcheren private flake-inputs over ssh. Kun aktivering blir root.
# Bruker-tjenestene restartes ikke av switch — de blir liggende paa gamle
# unit-filer til neste innlogging. Fragment-stiene lagres foer rebuild, saa
# Post-update kan restarte akkurat de som faktisk endret seg.
user_units_before=$(
  systemctl --user list-units --type=service --state=running --no-legend 2>/dev/null |
    awk '{print $1}' |
    while read -r u; do
      printf '%s %s\n' "$u" "$(readlink -f "$(systemctl --user show -p FragmentPath --value "$u")" 2>/dev/null)"
    done
) || true

log=$(mktemp -t nixlyos-rebuild.XXXXXX)
rebuild() {
  nixos-rebuild switch --sudo --keep-going --flake "$REPO#nixlyos" >>"$log" 2>&1 && return 0
  nixos-rebuild boot --sudo --keep-going --flake "$REPO#nixlyos" >>"$log" 2>&1 && return 2
  return 1
}

# Pakkenavn fra drv-stiene i feillinjene. Tomt ved eval- eller nedlastingsfeil.
failed_pkgs() {
  grep -E 'error:|failed' "$log" |
    grep -oP "/nix/store/[a-z0-9]{32}-\K[^' ]+(?=\.drv)" | sort -u | tr '\n' ' ' || true
}

ui_info "building (log: $log)"
rebuild && rc=0 || rc=$?

# Systemlukningen er atomisk: feiler én pakke, finnes det ingen generasjon aa
# aktivere. Naermeste vi kommer "resten oppdateres likevel" er aa rulle tilbake
# BARE kilden som eier den feilende pakka og bygge paa nytt — da beholder alle
# andre inputs sin nye revisjon.
if (( rc == 1 )); then
  failed=$(failed_pkgs)
  culprits=" " revert_proton=0
  for p in $failed; do
    case $p in
      proton-ge*) revert_proton=1;;
      nixly*)     culprits+="nixlypkgs ";;
      *)          culprits+="nixpkgs nixpkgs-unstable ";;
    esac
  done
  keep=()
  for i in $updated; do [[ $culprits == *" $i "* ]] || keep+=("$i"); done

  if [ -n "$failed" ]; then
    ui_warn "failed: ${failed% } — retrying without that source"
    cp "$lockbak" "$REPO/flake.lock"
    (( revert_proton )) && git -C "$REPO" checkout -- pkgs/proton-ge/pin.json || true
    (( ${#keep[@]} > 0 )) && nix flake update --refresh --flake "$REPO" "${keep[@]}" >>"$log" 2>&1 || true
    rebuild && rc=0 || rc=$?
    (( rc == 1 )) || ui_warn "kept at previous version: ${failed% } — everything else updated"
  fi
fi

# Siste utvei: hele lock-fila og proton-pinnen tilbake til forrige kjoering, saa
# maskina i det minste ender paa en generasjon som bygger. Hopper over naar
# forrige forsoek allerede kjoerte akkurat den kombinasjonen.
if (( rc == 1 )) && ! cmp -s "$lockbak" "$REPO/flake.lock"; then
  cp "$lockbak" "$REPO/flake.lock"
  git -C "$REPO" checkout -- pkgs/proton-ge/pin.json
  rebuild && rc=0 || rc=$?
  (( rc == 1 )) || ui_warn "update rolled back — previous input revisions restored"
fi

rm -f "$lockbak"
case $rc in
  0) rm -f "$log"; ui_ok "activated";;
  2) rm -f "$log"; ui_warn "activation failed — new generation set for next boot";;
  *)
    failed=$(failed_pkgs)
    if [ -n "$failed" ]; then
      ui_err "switch and boot both failed (Failed packages: ${failed% }). Try updating later or remove the failed package."
    else
      cat "$log" >&2
      ui_err "switch and boot both failed"
    fi
    ui_info "full log: $log"
    exit 1
    ;;
esac

# ── Hva kjoerer allerede paa nytt, og hva gjoer det ikke ──────────────
# switch har restartet system-tjenestene som endret seg. Bruker-manageren maa
# lese inn nye unit-filer selv, ellers kjoerer bruker-tjenestene paa gamle
# fragmenter til neste innlogging.
if (( rc == 0 )); then
  ui_head "Post-update"
  systemctl --user daemon-reload || true

  changed_units=()
  while read -r unit path; do
    [ -n "$unit" ] || continue
    # dbus-broker eier sesjonsbussen — en restart river hele skrivebordet.
    # Lyd-stacken hoppes over fordi en restart dreper aktive streams, mens den
    # gamle daemonen fungerer helt fint til neste innlogging.
    case $unit in
      dbus-*|pipewire*|wireplumber*) continue;;
    esac
    now=$(readlink -f "$(systemctl --user show -p FragmentPath --value "$unit")" 2>/dev/null || true)
    if [ -n "$now" ] && [ "$now" != "$path" ]; then
      changed_units+=("$unit")
    fi
  done <<<"$user_units_before"

  if (( ${#changed_units[@]} > 0 )); then
    systemctl --user restart "${changed_units[@]}" || true
    ui_ok "restarted user services: ${changed_units[*]}"
  fi

  # Kjernemodulene byttes ikke i en levende kjerne: bzImage, initrd og
  # modultreet gjelder foerst etter reboot.
  needs_reboot=""
  for part in kernel initrd kernel-modules; do
    [ "$(readlink -f "/run/booted-system/$part" 2>/dev/null)" = \
      "$(readlink -f "/run/current-system/$part" 2>/dev/null)" ] || needs_reboot+="$part "
  done

  # NVIDIA: userspace (libGL/libcuda) og kjernemodulen maa ha samme versjon.
  # Kjoerer en eldre modul enn generasjonen bruker, feiler GPU-apper foer
  # modulen lastes paa nytt — og det krever at hele sesjonen slipper GPU-en.
  nv_running=$(awk '/NVRM version/ {print $8}' /proc/driver/nvidia/version 2>/dev/null || true)
  nv_new=$(readlink -f /run/current-system/kernel-modules/lib/modules/*/kernel/drivers/video/nvidia.ko* 2>/dev/null |
    grep -oP 'nvidia-kernel-modules-\K[0-9.]+' | head -1 || true)

  if [ -n "$nv_running" ] && [ -n "$nv_new" ] && [ "$nv_running" != "$nv_new" ]; then
    ui_warn "nvidia $nv_running → $nv_new: reboot to load the new kernel module"
  elif [ -n "$needs_reboot" ]; then
    ui_warn "reboot required (${needs_reboot% } changed)"
  else
    ui_ok "everything running the new version — no reboot needed"
  fi
fi

# Auto-commit: styres av "Auto commit changes" paa Git-siden i nixlycc.
CONF="$HOME/.local/nixlyos/git.conf"
if [ -f "$CONF" ] && grep -qx 'autocommit=1' "$CONF"; then
  ui_head "Auto-commit"
  if [ -n "$(git -C "$REPO" status --porcelain)" ]; then
    git -C "$REPO" add -A
    git -C "$REPO" commit -m "auto: update $(date '+%Y-%m-%d %H:%M')"
  fi
  # Rebuild er allerede ferdig — en feilet push skal ikke felle skriptet.
  git -C "$REPO" push && ui_ok "pushed" || ui_warn "push failed"
fi
