{ pkgs, lib, ... }:

let
  # Runtime dependencies needed by the script
  deps = with pkgs; [ wimlib p7zip cabextract cpio xorriso cdrkit coreutils findutils gawk ];
  binPath = lib.makeBinPath deps;

  winstrip = pkgs.writeShellScriptBin "winstripping" ''
    #!/usr/bin/env bash
    set -euo pipefail

    # Ensure required tools are on PATH (from Home Manager profile)
    PATH="${binPath}:$PATH"

    die() { echo "error: $*" >&2; exit 1; }
    need() { command -v "$1" >/dev/null 2>&1 || die "Missing command: $1"; }

    volid_from_iso() {
      iso="$1"
      v=""
      if command -v xorriso >/dev/null 2>&1; then
        v=$(xorriso -indev "$iso" -pvd_info 2>/dev/null | awk -F': ' '/[Vv]olume id/ {print $2; exit}') || true
        if [ -n "$v" ]; then
          printf '%s\n' "$v"
          return 0
        fi
      fi
      if command -v isoinfo >/dev/null 2>&1; then
        v=$(isoinfo -d -i "$iso" 2>/dev/null | awk -F': ' '/[Vv]olume id/ {print $2; exit}') || true
        if [ -n "$v" ]; then
          printf '%s\n' "$v"
          return 0
        fi
      fi
      return 1
    }

    cmd_extract() {
      iso="$1"; workdir="$2"
      [ -f "$iso" ] || die "ISO not found: $iso"
      mkdir -p "$workdir/extracted"
      echo "==> Extracting ISO to $workdir/extracted"
      7z x -y -o"$workdir/extracted" "$iso" >/dev/null
      vid=""
      vid=$(volid_from_iso "$iso" || true)
      if [ -n "$vid" ]; then
        echo "$vid" > "$workdir/VOLUME_ID.txt"
        echo "Saved volume ID: $vid"
      else
        echo "warning: could not derive volume ID"
      fi
      echo "Done. You may now modify files under $workdir/extracted"
    }

    cmd_convert_esd() {
      workdir="$1"
      sources="$workdir/extracted/sources"
      [ -d "$sources" ] || die "Sources directory not found: $sources (run extract first)"

      esd="$sources/install.esd"
      wim="$sources/install.wim"
      [ -f "$esd" ] || die "install.esd not found in $sources"

      echo "==> Converting install.esd -> install.wim (LZX)"
      wimlib-imagex export "$esd" all "$wim" --compress=LZX >/dev/null
      echo "Removing original ESD"
      rm -f "$esd"
      echo "Done: $wim"
    }

    cmd_pack() {
      workdir="$1"; out_iso="$2"; shift 2 || true
      volid=""
      if [ $# -ge 1 ]; then
        volid="$1"
      fi
      srcdir="$workdir/extracted"
      [ -d "$srcdir" ] || die "Extracted tree not found: $srcdir (run extract first)"

      if [ -z "$volid" ] && [ -f "$workdir/VOLUME_ID.txt" ]; then
        volid=$(cat "$workdir/VOLUME_ID.txt")
      fi
      if [ -z "$volid" ]; then
        volid="WIN11_CUSTOM"
      fi

      # Ensure boot loaders exist
      bios_boot="$srcdir/boot/etfsboot.com"
      efi_boot="$srcdir/efi/microsoft/boot/efisys.bin"
      efi_boot_np="$srcdir/efi/microsoft/boot/efisys_noprompt.bin"
      [ -f "$bios_boot" ] || die "Missing BIOS boot image: boot/etfsboot.com"
      if [ -f "$efi_boot" ]; then
        :
      elif [ -f "$efi_boot_np" ]; then
        efi_boot="$efi_boot_np"
      else
        die "Missing UEFI boot image: efi/microsoft/boot/efisys(.noprompt).bin"
      fi

      # Compute relative path of efisys image to srcdir (avoid Nix interpolation here)
      rel_efi="$(printf '%s' "$efi_boot" | sed -e "s#^$srcdir/##")"

      echo "==> Building ISO: $out_iso (VOLID=$volid)"
      if command -v xorriso >/dev/null 2>&1; then
        xorriso -as mkisofs \
          -iso-level 3 \
          -o "$out_iso" \
          -full-iso9660-filenames \
          -volid "$volid" \
          -eltorito-boot boot/etfsboot.com \
            -no-emul-boot -boot-load-size 8 -boot-info-table \
          -eltorito-alt-boot \
            -e "$rel_efi" -no-emul-boot \
          -isohybrid-gpt-basdat \
          -udf -J -joliet-long \
          "$srcdir"
      else
        need genisoimage
        genisoimage \
          -iso-level 3 \
          -o "$out_iso" \
          -V "$volid" \
          -b boot/etfsboot.com -no-emul-boot -boot-load-size 8 -boot-info-table \
          -eltorito-alt-boot -e "$rel_efi" -no-emul-boot \
          -udf -J -joliet-long \
          "$srcdir"
      fi
      echo "Done: $out_iso"
    }

    usage() {
      cat <<USAGE
    winstripping - helper for Windows ISO strip/repack

    Commands:
      extract <win.iso> <workdir>      Extract ISO into <workdir>/extracted, save VOLID
      convert-esd <workdir>            Convert sources/install.esd -> install.wim (LZX)
      pack <workdir> <out.iso> [VOLID] Repack extracted tree into a bootable ISO

    Notes:
      - After 'extract', manually remove/add files under <workdir>/extracted as needed.
      - 'convert-esd' is optional but recommended if you modified sources.
      - Repacking uses xorriso if available; falls back to genisoimage.
    USAGE
    }

    main() {
      cmd=""
      if [ $# -ge 1 ]; then
        cmd="$1"; shift
      fi
      case "$cmd" in
        extract) [ $# -ge 2 ] || { usage; exit 2; }; cmd_extract "$@" ;;
        convert-esd) [ $# -ge 1 ] || { usage; exit 2; }; cmd_convert_esd "$@" ;;
        pack) [ $# -ge 2 ] || { usage; exit 2; }; cmd_pack "$@" ;;
        -h|--help|help|"") usage ;;
        *) echo "Unknown command: $cmd"; usage; exit 2 ;;
      esac
    }

    main "$@"
  '';
in {
  # Install the script and runtime deps into the user's profile
  home.packages = [ winstrip ] ++ deps;
}
