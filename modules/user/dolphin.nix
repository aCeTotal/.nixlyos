{ pkgs, lib, ... }:

{
  # Packages extending Dolphin with modern KDE features.
  # Ark's "Extract here" needs a CLI tool on PATH per format.
  home.packages = with pkgs; [
    # Archive backends the Ark dispatcher calls.
    p7zip          # 7z, zip, xz fallback
    unar           # unar/lsar - mange formater inkl. RAR/zip med encoding-fix
    lhasa          # LHA/LZH
    arj            # ARJ
    lzip lzop lz4 zstd  # moderne komprimeringsformater
    cpio           # cpio-arkiver (rpm-pakker)
    libarchive     # bsdtar - extra format-coverage

    # KDE thumbnailers and image formats
    kdePackages.kimageformats        # HEIC, AVIF, JXL, RAW
    kdePackages.qtimageformats       # TIFF, WebP, JP2, ICNS
    kdePackages.kdesdk-thumbnailers  # PS, EPS, plain text, srt
    kdePackages.svgpart              # SVG-preview/embed

    # KIO extensions
    kdePackages.kdenetwork-filesharing  # "Share via Samba" høyreklikk
    kdePackages.kio-gdrive              # gdrive:// protokoll
    kdePackages.kdialog                 # KDE-dialoger for scripts

    # Default openers Dolphin launches
    kdePackages.gwenview    # bildeviser (default)
    kdePackages.okular      # PDF/dokumentviser
    kdePackages.filelight   # disk-usage analyse (Tools-menyen)
    kdePackages.kompare     # diff-viewer
    krename                 # batch-rename
    kdiff3                  # 3-veis diff/merge
  ];

  # Hardening against hangs when an NFS or SMB server is down, in five layers:
  # NFS automount, SMB timeout, KIO timeout, Baloo exclusion, no remote previews.

  # Read by libsmbclient; the connect timeout is in milliseconds.
  home.file.".smb/smb.conf".text = ''
    [global]
        client min protocol = SMB2
        client max protocol = SMB3
        client ipc max protocol = SMB3
        # Skip WINS and lmhosts, which hang without a WINS server.
        name resolve order = host bcast
        # A failed connect gives up after 3 s instead of 30.
        client connection timeout = 3000
        socket options = TCP_NODELAY IPTOS_LOWDELAY
  '';

  # Global KIO timeouts; the default connect timeout is 20 s.
  xdg.configFile."kioslaverc".text = ''
    [Connection-Settings]
    ConnectTimeout=3
    ProxyConnectTimeout=3
    ResponseTimeout=5
    ReadTimeout=10

    [Browser Settings][SMB]
    Workgroup=
  '';

  # Baloo must not scan network mounts; stat on a dead mount can hang.
  xdg.configFile."baloofilerc".text = ''
    [Basic Settings]
    Indexing-Enabled=true

    [General]
    dbVersion=2
    exclude filters version=9
    exclude folders[$e]=/mnt/,/run/media/,$HOME/.cache/,$HOME/.local/share/Trash/,$HOME/.gvfs/,$HOME/.local/share/baloo/
    only basic indexing=false
  '';

  # No previews for remote files.
  # Seeded, not symlinked, since Dolphin writes window state to it.
  home.activation.dolphinrcSeed = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    target="$HOME/.config/dolphinrc"
    if [ -L "$target" ] || [ ! -e "$target" ]; then
      run rm -f "$target"
      run install -m 644 ${pkgs.writeText "dolphinrc-seed" ''
        [PreviewSettings]
        MaximumRemoteSize=0
      ''} "$target"
    fi
  '';
}
