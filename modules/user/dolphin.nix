{ pkgs, ... }:

{
  # Pakker som utvider Dolphin med moderne KDE-features.
  # Ark sin "Extract here" trenger CLI-tools i PATH for hvert format.
  # unrar/zip/unzip/rar er allerede systemwide i modules/system/packages.nix.
  home.packages = with pkgs; [
    # Arkiv-backends - Ark dispatcher kaller disse
    p7zip          # 7z, zip, xz fallback
    unar           # unar/lsar - mange formater inkl. RAR/zip med encoding-fix
    lhasa          # LHA/LZH
    arj            # ARJ
    lzip lzop lz4 zstd  # moderne komprimeringsformater
    cpio           # cpio-arkiver (rpm-pakker)
    libarchive     # bsdtar - extra format-coverage

    # KDE thumbnailers og bildeformater
    kdePackages.kimageformats        # HEIC, AVIF, JXL, RAW
    kdePackages.qtimageformats       # TIFF, WebP, JP2, ICNS
    kdePackages.kdesdk-thumbnailers  # PS, EPS, plain text, srt
    kdePackages.svgpart              # SVG-preview/embed

    # KIO-utvidelser
    kdePackages.kdenetwork-filesharing  # "Share via Samba" høyreklikk
    kdePackages.kio-gdrive              # gdrive:// protokoll
    kdePackages.kdialog                 # KDE-dialoger for scripts

    # Standard openers Dolphin starter
    kdePackages.gwenview    # bildeviser (default)
    kdePackages.okular      # PDF/dokumentviser
    kdePackages.filelight   # disk-usage analyse (Tools-menyen)
    kdePackages.kompare     # diff-viewer
    krename                 # batch-rename
    kdiff3                  # 3-veis diff/merge
  ];

  # Hardener mot henging når NFS/SMB-server er nede.
  # Lagene er:
  #   1. NFS: systemd automount + ping-sjekk i modules/core/nfs.nix (1s fail).
  #   2. SMB: kort smbclient-timeout via ~/.smb/smb.conf.
  #   3. KIO: kort connect/response-timeout for alle workers.
  #   4. Baloo: ekskluder nettverksmounts fra indeksering.
  #   5. Dolphin: ingen previews på remote URL (smb://, sftp://, nfs://).

  # libsmbclient (brukt av kio-extras smb-worker) leser denne.
  # client connection timeout er i millisekunder; default 30000.
  home.file.".smb/smb.conf".text = ''
    [global]
        client min protocol = SMB2
        client max protocol = SMB3
        client ipc max protocol = SMB3
        # Hopp over WINS/lmhosts som henger uten DNS/WINS-server.
        name resolve order = host bcast
        # Mislykket connect feiler etter 3s, ikke 30s.
        client connection timeout = 3000
        socket options = TCP_NODELAY IPTOS_LOWDELAY
  '';

  # KIO globale timeouts. Default ConnectTimeout er 20s.
  xdg.configFile."kioslaverc".text = ''
    [Connection-Settings]
    ConnectTimeout=3
    ProxyConnectTimeout=3
    ResponseTimeout=5
    ReadTimeout=10

    [Browser Settings][SMB]
    Workgroup=
  '';

  # Baloo skal ikke skanne nettverksmounts - stat på død mount kan henge.
  xdg.configFile."baloofilerc".text = ''
    [Basic Settings]
    Indexing-Enabled=true

    [General]
    dbVersion=2
    exclude filters version=9
    exclude folders[$e]=/mnt/,/run/media/,$HOME/.cache/,$HOME/.local/share/Trash/,$HOME/.gvfs/,$HOME/.local/share/baloo/
    only basic indexing=false
  '';

  # Dolphin: ingen forhåndsvisning av remote-filer (smb/sftp/nfs).
  # MaximumRemoteSize=0 → previews skrus av på alt som ikke er lokalt.
  xdg.configFile."dolphinrc".text = ''
    [PreviewSettings]
    MaximumRemoteSize=0
  '';
}
