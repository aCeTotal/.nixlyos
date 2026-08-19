#!/usr/bin/env bash
# Hardware-deteksjon foer hver eval (install, update, rebuild). Nix-eval er
# pure og kan ikke lese /sys selv, saa dette scriptet skriver resultatet inn
# i repoet:
#
#   modules/core/default.nix        cpu/ + gpu/-imports byttes ut
#   modules/core/gpu/detected.nix   GENERERT: PCI-bus-IDer + NVIDIA-branch
#   modules/core/hw/profile.nix     GENERERT: laptop/modell-spesifikke moduler
#
# Ingen forks i hot path: leser /sys og /proc direkte. Er alt allerede
# korrekt, avsluttes scriptet uten aa roere en fil (normaltilfellet).
set -euo pipefail

REPO=${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}
. "$REPO/scripts/ui.sh"
DEFAULT_NIX="$REPO/modules/core/default.nix"
[[ -f "$DEFAULT_NIX" ]] || { ui_err "missing $DEFAULT_NIX"; exit 1; }

REGISTER="$REPO/scripts/laptop-register"

# Skriv fil bare naar innholdet endrer seg (holder repoet rent), og legg den
# i git-indeksen om den er ny — flake-eval ser ikke untracked filer.
# safe.directory: installer/systemd kjoerer som root paa et bruker-eid repo.
write_generated() {
  local path=$1 content=$2 rel=${1#"$REPO"/}
  if [[ -f $path ]] && [[ "$(<"$path")" == "$content" ]]; then
    return 0
  fi
  mkdir -p "$(dirname "$path")"
  # Redirect (ikke mv) saa eier/modus beholdes naar scriptet kjoerer som root.
  printf '%s\n' "$content" > "$path"
  ui_info "wrote $rel"
  if [[ -d "$REPO/.git" ]] && command -v git >/dev/null 2>&1; then
    git -C "$REPO" -c safe.directory='*' ls-files --error-unmatch "$rel" >/dev/null 2>&1 ||
      git -C "$REPO" -c safe.directory='*' add -f "$rel" || true
  fi
}

# "GS66 Stealth 10UG" -> "gs66-stealth-10ug"
slug() {
  local s=${1,,}
  s=${s//[^a-z0-9]/-}
  while [[ $s == *--* ]]; do s=${s//--/-}; done
  s=${s#-}; s=${s%-}
  printf '%s\n' "$s"
}

# ── CPU: vendor, kjerner, feature-nivaa ───────────────────────────────
cpu_mod="" cpu_flags="" nproc=0
while IFS= read -r line; do
  case "$line" in
    processor*) (( ++nproc ));;
    vendor_id*GenuineIntel*) [[ -n $cpu_mod ]] || cpu_mod="./cpu/intel.nix";;
    vendor_id*AuthenticAMD*) [[ -n $cpu_mod ]] || cpu_mod="./cpu/amd.nix";;
    flags*) [[ -n $cpu_flags ]] || cpu_flags=" ${line#*: } ";;
  esac
done < /proc/cpuinfo
(( nproc > 0 )) || nproc=1

# x86-64 psABI-nivaa. Brukes til aa velge konservative innstillinger paa
# gammel CPU (se hw/resources.nix-konsumentene).
has_flag() { [[ $cpu_flags == *" $1 "* ]]; }
cpu_level=1
if has_flag sse4_2 && has_flag popcnt && has_flag cx16; then cpu_level=2; fi
if (( cpu_level == 2 )) && has_flag avx2 && has_flag bmi2 && has_flag fma; then cpu_level=3; fi
if (( cpu_level == 3 )) && has_flag avx512f && has_flag avx512vl; then cpu_level=4; fi

mem_gib=0
while IFS= read -r line; do
  if [[ $line == MemTotal:* ]]; then
    set -- $line
    mem_gib=$(( $2 / 1048576 ))
    break
  fi
done < /proc/meminfo
(( mem_gib > 0 )) || mem_gib=1

# ── GPU ───────────────────────────────────────────────────────────────
# PCI class 0x03xxxx = display controller. vendor: 10de=NVIDIA,
# 8086=Intel, 1002=AMD.
has_nvidia=0 has_amd=0 has_intel_igpu=0 has_intel_dgpu=0
bus_nvidia="" bus_intel="" bus_amd="" dev_nvidia=""
amd_legacy=0 intel_legacy=0

# Intel DG2/Alchemist (Arc A310–A770). Alt annet fra 8086 behandles som iGPU.
dg2_ids=" 5690 5691 5692 5693 5694 5695 5696 5697 56a0 56a1 56a2 56a3 56a5 56a6 "

# AMD pre-GCN / GCN1 (Southern Islands) / GCN2 (Sea Islands). Disse maa
# tvinges over paa amdgpu (eller bli paa radeon), og har ikke ppfeaturemask
# eller moderne VA-API. Eksplisitte intervaller — AMDs ID-rom er ikke
# monotont: Polaris starter paa 0x67c0 rett etter Hawaii (0x67a0-0x67bf), og
# Vega (0x6860-0x687f) ligger MELLOM Pitcairn (0x6800-0x685f) og Evergreen
# (0x6880+).
amd_is_legacy() {
  local i=$1
  (( i >= 0x1304 && i <= 0x131d )) ||   # Kaveri  (GCN2 APU)
  (( i >= 0x4000 && i <= 0x5fff )) ||   # R300/R400/RV370
  (( i >= 0x6600 && i <= 0x667f )) ||   # Oland/Hainan (GCN1), Bonaire (GCN2)
  (( i >= 0x6720 && i <= 0x677f )) ||   # Northern Islands (TeraScale 3)
  (( i >= 0x6780 && i <= 0x67bf )) ||   # Tahiti (GCN1), Hawaii (GCN2)
  (( i >= 0x6800 && i <= 0x685f )) ||   # Pitcairn/Verde (GCN1), Trinity APU
  (( i >= 0x6880 && i <= 0x68ff )) ||   # Evergreen (TeraScale 2)
  (( i >= 0x7100 && i <= 0x71ff )) ||   # R520/R580
  # 0x9400-0x986f: R600/RS780/RS880 (TeraScale) + Kabini/Mullins (GCN2 APU).
  # Stopper foer 0x9870 — Carrizo/Bristol (0x9870-0x9877) og Stoney (0x98e4)
  # er GCN3 og hoerer paa amdgpu uten force-enable.
  (( i >= 0x9400 && i <= 0x986f ))
}

# Intel Gen7.5 og eldre: intel-media-driver (iHD) krever Gen8+/Broadwell, saa
# disse maa ha i965. Broadwell starter paa 0x1602 — alt under 0x0f40 er
# Ironlake/SNB/IVB/HSW/Bay Trail, 0x25xx-0x2fxx er Gen3/4, 0xa0xx Pineview.
intel_is_legacy() {
  local i=$1
  (( i <= 0x0f3f )) ||
  (( i >= 0x2500 && i <= 0x2fff )) ||
  (( i >= 0xa000 && i <= 0xa0ff ))
}

# sysfs-adresse (hex, domain:bus:dev.fn) -> NixOS prime-busId. Merk:
# hardware.nvidia.prime.*BusId tar DESIMAL adresse, mens lspci/sysfs er
# hex — formatet er "PCI:bus@domain:device:function".
to_bus_id() {
  local a=$1 dom bus slot fn
  dom=${a%%:*}; a=${a#*:}
  bus=${a%%:*}; a=${a#*:}
  slot=${a%%.*}; fn=${a#*.}
  printf 'PCI:%d@%d:%d:%d\n' "$((16#$bus))" "$((16#$dom))" "$((16#$slot))" "$((16#$fn))"
}

for dev in /sys/bus/pci/devices/*; do
  read -r cls < "$dev/class"
  [[ $cls == 0x03* ]] || continue
  read -r vnd < "$dev/vendor"
  read -r did < "$dev/device"
  addr=${dev##*/}
  case "$vnd" in
    0x10de)
      has_nvidia=1
      [[ -n $bus_nvidia ]] || { bus_nvidia=$(to_bus_id "$addr"); dev_nvidia=${did#0x}; }
      ;;
    0x1002)
      has_amd=1
      [[ -n $bus_amd ]] || bus_amd=$(to_bus_id "$addr")
      amd_is_legacy "$((16#${did#0x}))" && amd_legacy=1
      ;;
    0x8086)
      if [[ $dg2_ids == *" ${did#0x} "* ]]; then
        has_intel_dgpu=1
      else
        has_intel_igpu=1
        [[ -n $bus_intel ]] || bus_intel=$(to_bus_id "$addr")
        intel_is_legacy "$((16#${did#0x}))" && intel_legacy=1
      fi
      ;;
  esac
done

# ── NVIDIA-arkitektur -> driver-branch ────────────────────────────────
# PCI-device-ID -> arkitektur. Intervallene under er DISJUNKTE og maa
# sjekkes i rekkefoelge: Fermi og Kepler har interleavede ID-blokker
# (GF119=0x1040, GK110=0x1003, GF114=0x1200, GK208=0x1290), saa et enkelt
# "stoerre enn"-kutt er umulig. Heuristikk — pin branch i
# scripts/laptop-register om et kort havner feil.
#   595 (latest)  Turing og nyere (0x1e00+)
#   580           Maxwell / Pascal / Volta  (droppet i 590+)
#   470           Kepler
#   390           Fermi
#   340           Tesla
nvidia_arch="" nvidia_branch=""
if (( has_nvidia )) && [[ -n $dev_nvidia ]]; then
  id=$((16#$dev_nvidia))
  arch_of() {
    local i=$1
    if   (( i <= 0x06bf )); then echo tesla
    elif (( i <= 0x09ff )); then echo fermi
    elif (( i <= 0x0cff )); then echo tesla
    elif (( i <= 0x0fbf )); then echo fermi
    elif (( i <= 0x103f )); then echo kepler   # GK110
    elif (( i <= 0x117f )); then echo fermi    # GF119, GF108, GF117 (0x1140)
    elif (( i <= 0x11ff )); then echo kepler   # GK104/106/107
    elif (( i <= 0x127f )); then echo fermi    # GF114/GF116
    elif (( i <= 0x133f )); then echo kepler   # GK208 (0x1280+), GK208M
    elif (( i <= 0x1dff )); then echo maxwell_pascal_volta
    else                         echo turing_plus
    fi
  }
  nvidia_arch=$(arch_of "$id")
  case "$nvidia_arch" in
    turing_plus)          nvidia_branch="latest";;
    maxwell_pascal_volta) nvidia_branch="legacy_580";;
    kepler)               nvidia_branch="legacy_470";;
    # Fermi/Tesla trenger legacy_390/legacy_340, som er broken = true i
    # nixpkgs (bygger ikke mot moderne kernel). Et system som ikke bygger er
    # verre enn nouveau — se gpu/nvidia_nouveau.nix.
    fermi|tesla)          nvidia_branch="nouveau";;
  esac
fi

# ── DMI: laptop eller stasjonaer + modell ─────────────────────────────
dmi() { [[ -r /sys/class/dmi/id/$1 ]] && read -r _v < "/sys/class/dmi/id/$1" && printf '%s\n' "$_v" || true; }

chassis=$(dmi chassis_type)
sys_vendor=$(dmi sys_vendor)
product=$(dmi product_name)
family=$(dmi product_family)
board=$(dmi board_name)

# SMBIOS chassis types: 8 Portable, 9 Laptop, 10 Notebook, 11 Hand Held,
# 14 Sub Notebook, 30 Tablet, 31 Convertible, 32 Detachable.
is_laptop=0
case "$chassis" in
  8|9|10|11|14|30|31|32) is_laptop=1;;
  # Ukjent/feilrapportert chassis: fall tilbake paa et faktisk batteri.
  # Krever type=Battery (en UPS eller et musbatteri melder Device/UPS).
  *) for b in /sys/class/power_supply/*; do
       [[ -r $b/type && -r $b/present ]] || continue
       read -r t < "$b/type"; [[ $t == Battery ]] || continue
       [[ -e $b/scope ]] && { read -r sc < "$b/scope"; [[ $sc == Device ]] && continue; }
       is_laptop=1; break
     done;;
esac

# Vendor-slug slik nixos-hardware navngir modulene sine.
vendor_slug=""
case "${sys_vendor,,}" in
  *micro-star*|*msi*)        vendor_slug=msi;;
  *lenovo*)                  vendor_slug=lenovo;;
  *dell*)                    vendor_slug=dell;;
  *asus*)                    vendor_slug=asus;;
  *hewlett*|hp*|*" hp"*)     vendor_slug=hp;;
  *framework*)               vendor_slug=framework;;
  *acer*)                    vendor_slug=acer;;
  *apple*)                   vendor_slug=apple;;
  *tuxedo*)                  vendor_slug=tuxedo;;
  *system76*)                vendor_slug=system76;;
  *gpd*)                     vendor_slug=gpd;;
  *razer*)                   vendor_slug=razer;;
  *gigabyte*)                vendor_slug=gigabyte;;
  *"star labs"*|*starlabs*)  vendor_slug=starlabs;;
  *slimbook*)                vendor_slug=slimbook;;
  *microsoft*)               vendor_slug=microsoft;;
  *samsung*)                 vendor_slug=samsung;;
  *toshiba*|*dynabook*)      vendor_slug=toshiba;;
  *huawei*)                  vendor_slug=huawei;;
  *panasonic*)               vendor_slug=panasonic;;
  *pcspecialist*|*"pc specialist"*) vendor_slug=pcspecialist;;
  *supermicro*)              vendor_slug=supermicro;;
  *intel*)                   vendor_slug=intel;;
  *)                         vendor_slug=$(slug "$sys_vendor");;
esac

# Modell-kandidater i prioritert rekkefoelge. nixos-hardware har 400+
# moduler navngitt <vendor>-<modell>; nix-sida importerer den FOERSTE som
# faktisk finnes, saa en kandidat som ikke traeffer er gratis.
candidates=()
[[ -n $vendor_slug && -n $product ]] && candidates+=("$vendor_slug-$(slug "$product")")
[[ -n $vendor_slug && -n $board   ]] && candidates+=("$vendor_slug-$(slug "$board")")
[[ -n $vendor_slug && -n $family  ]] && candidates+=("$vendor_slug-$(slug "$family")")

# ── Register: eksplisitte overstyringer ───────────────────────────────
# Format per linje:  vendor-glob | produkt-glob | moduler(komma) | nvidia-branch
# Foerste treff vinner. Globs matches mot smaa bokstaver.
reg_modules="" reg_branch=""
if [[ -f $REGISTER ]]; then
  while IFS='|' read -r r_vendor r_product r_mods r_branch; do
    [[ -z ${r_vendor// } || ${r_vendor// } == \#* ]] && continue
    r_vendor=${r_vendor// }
    # trim (ingen forks — registeret leses ved hver eval)
    r_product=${r_product#"${r_product%%[![:space:]]*}"}
    r_product=${r_product%"${r_product##*[![:space:]]}"}
    [[ ${vendor_slug,,} == ${r_vendor,,} || $r_vendor == '*' ]] || continue
    [[ ${product,,} == ${r_product,,} || $r_product == '*' ]] || continue
    reg_modules=${r_mods// }
    reg_branch=${r_branch// }
    break
  done < "$REGISTER"
fi
[[ -n $reg_branch ]] && nvidia_branch=$reg_branch

# ── Generisk sett: laptop vs stasjonaer, SSD vs HDD ───────────────────
rotational=1
for b in /sys/block/*; do
  [[ -r $b/removable && -r $b/queue/rotational ]] || continue
  read -r rm < "$b/removable"; [[ $rm == 0 ]] || continue
  read -r rot < "$b/queue/rotational"
  [[ $rot == 0 ]] && { rotational=0; break; }
done

generic=()
if (( is_laptop )); then
  generic+=("common-pc-laptop")
  (( rotational )) && generic+=("common-pc-laptop-hdd") || generic+=("common-pc-laptop-ssd")
else
  generic+=("common-pc")
  (( rotational )) && generic+=("common-pc-hdd") || generic+=("common-pc-ssd")
fi

# Register kan legge til moduler, og pseudo-modulen "no-model" slaar av den
# DMI-utledede modellmodulen. Escape-luka finnes fordi nixos-hardware foelger
# unstable: en modellmodul kan sette opsjoner som ikke finnes i den stable
# nixpkgs dette flaket bruker (f.eks. hardware.intelgpu.vaapiDriver), og da
# feiler hele evalueringen.
if [[ -n $reg_modules ]]; then
  IFS=',' read -r -a extra <<< "$reg_modules"
  for m in "${extra[@]}"; do
    if [[ $m == no-model ]]; then
      candidates=()
    else
      generic+=("$m")
    fi
  done
fi

# ── GPU-modulvalg ─────────────────────────────────────────────────────
gpu_mods=()
if (( has_nvidia )); then
  if [[ $nvidia_branch == nouveau ]]; then
    gpu_mods+=("./gpu/nvidia_nouveau.nix")
  elif [[ -n $nvidia_branch && $nvidia_branch != latest ]]; then
    # Gammelt kort: eget profilmodul som pinner legacy-branchen og bare
    # slaar paa prime naar det faktisk finnes en iGPU.
    gpu_mods+=("./gpu/nvidia_legacy.nix")
  elif (( has_intel_igpu )); then
    # Hybrid/Optimus: prime-offload mot iGPU-drevet panel.
    gpu_mods+=("./gpu/nvidia_intel.nix")
  else
    gpu_mods+=("./gpu/nvidia_only.nix")
  fi
fi
(( has_intel_dgpu )) && gpu_mods+=("./gpu/intel.nix")
# iGPU-modulen eier i915-firmware og VA-API-dekoding for kompositoren, saa
# den skal med ogsaa naar NVIDIA driver sesjonen.
if (( has_intel_igpu )); then
  (( intel_legacy )) && gpu_mods+=("./gpu/intel_legacy.nix") || gpu_mods+=("./gpu/intel_igpu.nix")
fi
# AMD-modulen er felles for iGPU og dGPU, men dropp den naar NVIDIA driver
# sesjonen — radeonsi-sessionVariables ville da peke feil.
if (( has_amd && !has_nvidia )); then
  (( amd_legacy )) && gpu_mods+=("./gpu/amd_legacy.nix") || gpu_mods+=("./gpu/amd.nix")
fi

# ── Enheter som skal styre tjenester ──────────────────────────────────
# Bluetooth: controlleren dukker opp i /sys/class/bluetooth naar btusb/btintel
# er lastet. USB-fallback for live-ISO der modulen ikke er lastet enda:
# bDeviceClass e0 = Wireless Controller.
has_bt=0
for b in /sys/class/bluetooth/*; do [[ -e $b ]] && { has_bt=1; break; }; done
if (( !has_bt )); then
  for u in /sys/bus/usb/devices/*/bDeviceClass; do
    [[ -r $u ]] || continue
    read -r c < "$u"; [[ $c == e0 ]] && { has_bt=1; break; }
  done
fi

# Fingeravtrykksleser: kjente USB-vendorer for fprintd-stoettede lesere.
fp_vendors=" 27c6 138a 06cb 1c7a 08ff 04f3 05ba 298d 1491 "
has_fp=0
for u in /sys/bus/usb/devices/*/idVendor; do
  [[ -r $u ]] || continue
  read -r v < "$u"
  [[ $fp_vendors == *" $v "* ]] && { has_fp=1; break; }
done

# Thunderbolt: en domain dukker opp i /sys/bus/thunderbolt/devices naar
# kontrolleren finnes. boltd trengs for enhetsgodkjenning.
has_tb=0
for t in /sys/bus/thunderbolt/devices/domain*; do [[ -e $t ]] && { has_tb=1; break; }; done

# ── Skriv hw/devices.nix ──────────────────────────────────────────────
# WiFi gates bevisst IKKE: NetworkManager maa vaere paa uansett (ethernet),
# og wifi-innstillingene i networking.nix er no-ops uten et wifi-kort.
write_generated "$REPO/modules/core/hw/devices.nix" \
"{ lib, ... }:

{$( ((has_bt)) || printf '%s' "
  hardware.bluetooth.enable = lib.mkForce false;
  services.blueman.enable = lib.mkForce false;
")$( ((has_fp)) && printf '%s' "
  services.fprintd.enable = true;
")$( ((has_tb)) && printf '%s' "
  services.hardware.bolt.enable = true;
")
}"

# ── Skriv hw/dmi.nix ──────────────────────────────────────────────────
# Ren data. Moduler som maa vite hvilken maskin de staar paa (msi-ec pinner
# EC-firmware per hovedkort) leser herfra i stedet for aa hardkode.
write_generated "$REPO/modules/core/hw/dmi.nix" \
"{
  vendor = \"$sys_vendor\";
  vendorSlug = \"$vendor_slug\";
  product = \"$product\";
  board = \"$board\";
  chassis = \"$chassis\";
  isLaptop = $( ((is_laptop)) && echo true || echo false );
}"

# ── Skriv hw/resources.nix ────────────────────────────────────────────
# nix-bygg: max-jobs x cores maa holde seg innenfor RAM, ikke bare innenfor
# kjernetallet — en parallell C++-link tar GiB, og nix-daemon har MemoryMax
# 90 % (nix.nix). Ett job per 8 GiB og aldri mer enn en fjerdedel av
# kjernene; cores per job begrenses av BAADE kjerner og RAM (1 per 4 GiB).
# 16 GiB / 16 traader -> 1 x 3 (samme konservative profil som det hardkodede
# 1/2). 128 GiB / 64 traader -> 16 x 2.
jobs=$(( mem_gib / 8 ))
(( jobs > nproc / 4 )) && jobs=$(( nproc / 4 ))
(( jobs < 1 )) && jobs=1
build_cores=$(( nproc / jobs / 4 ))
mem_cores=$(( mem_gib / 4 ))
(( build_cores > mem_cores )) && build_cores=$mem_cores
(( build_cores < 2 )) && build_cores=2

write_generated "$REPO/modules/core/hw/resources.nix" \
"{
  cores = $nproc;
  memGiB = $mem_gib;
  cpuLevel = $cpu_level;
  maxJobs = $jobs;
  buildCores = $build_cores;
}"

# ── Skriv gpu/detected.nix ────────────────────────────────────────────
write_generated "$REPO/modules/core/gpu/detected.nix" \
"{
  nvidia = \"$bus_nvidia\";
  intel = \"$bus_intel\";
  amd = \"$bus_amd\";
  nvidiaArch = \"$nvidia_arch\";
  nvidiaBranch = \"${nvidia_branch:-latest}\";
}"

# ── Skriv hw/profile.nix ──────────────────────────────────────────────
cand_nix="" gen_nix=""
for c in "${candidates[@]}"; do cand_nix+="    \"$c\"
"; done
for g in "${generic[@]}"; do gen_nix+="    \"$g\"
"; done

# msi-ec: EC-driver for MSI-laptoper (fan/shift-mode). Skal ikke lastes paa
# annen hardware — gates her istedenfor i core/default.nix.
extra_imports=""
if (( is_laptop )) && [[ $vendor_slug == msi ]]; then
  extra_imports="
    ++ [ ../../system/msi-ec.nix ]"
fi

# TLP: common-pc-laptop slaar paa TLP naar power-profiles-daemon er av (som
# den er i cpu/*.nix). TLP eier da governor/EPP og overstyrer
# performance-governoren fra perf.nix — én eier, saa TLP holdes av.
tlp_line=""
(( is_laptop )) && tlp_line="

  services.tlp.enable = lib.mkForce false;"

write_generated "$REPO/modules/core/hw/profile.nix" \
"{ inputs, lib, ... }:

let
  hw = inputs.nixos-hardware.nixosModules;

  candidates = [
$cand_nix  ];

  generic = [
$gen_nix  ];

  model = lib.findFirst (n: builtins.hasAttr n hw) null candidates;
  generic' = builtins.filter (n: builtins.hasAttr n hw) generic;
  missing = builtins.filter (n: !(builtins.hasAttr n hw)) generic;
in
lib.warnIf (missing != [ ])
  \"hw/profile.nix: ukjente nixos-hardware-moduler: \${toString missing}\"
{
  imports =
    map (n: hw.\${n}) generic'
    ++ lib.optional (model != null) hw.\${model}$extra_imports;$tlp_line
}"

# ── Er default.nix allerede korrekt? ─────────────────────────────────
wanted=()
[[ -n $cpu_mod ]] && wanted+=("$cpu_mod")
wanted+=("${gpu_mods[@]}")

if (( ${#wanted[@]} == 0 )); then
  ui_warn "no known CPU vendor or GPU found — leaving default.nix alone"
  exit 0
fi

case $cpu_mod in
  *intel*) cpu_name="Intel";;
  *amd*)   cpu_name="AMD";;
  *)       cpu_name="Unknown";;
esac
gpu_names=()
(( has_nvidia )) && gpu_names+=("Nvidia")
(( has_amd )) && gpu_names+=("AMD")
(( has_intel_igpu || has_intel_dgpu )) && gpu_names+=("Intel")
gpu_name=$(IFS=+; echo "${gpu_names[*]}")
ui_ok "$cpu_name CPU and ${gpu_name//+/ + } GPU detected!"

have=$(grep -oE '\./(cpu|gpu)/[a-z0-9_]+\.nix' "$DEFAULT_NIX" | grep -v '/detected\.nix' | sort || true)
want=$(printf '%s\n' "${wanted[@]}" | sort)
if [[ "$have" == "$want" ]]; then
  exit 0
fi

# ── Bytt ut alle cpu/ + gpu/-linjer med de detekterte ────────────────
tmp=$(mktemp)
printf '%s\n' "${wanted[@]}" |
  awk -v RS='\n' 'NR==FNR { w[FNR]=$0; n=FNR; next }
    /\.\/(cpu|gpu)\/[a-z0-9_]+\.nix/ {
      if (!seen) { for (i=1; i<=n; i++) print "    " w[i]; seen=1 }
      next
    }
    # Ankeret i default.nix bestemmer hvor linjene havner. Mangler det (eller
    # er alle cpu/gpu-linjene borte), settes de inn foer den lukkende ];
    /# <detect-hw: cpu \+ gpu>/ && !seen {
      print; for (i=1; i<=n; i++) print "    " w[i]; seen=1; next
    }
    /^  \];/ && !seen { for (i=1; i<=n; i++) print "    " w[i]; seen=1 }
    { print }
  ' - "$DEFAULT_NIX" > "$tmp"

cat "$tmp" > "$DEFAULT_NIX"
rm -f "$tmp"

ui_info "default.nix updated: ${wanted[*]}"
