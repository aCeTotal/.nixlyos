final: prev: {
  # wfica sjekker XDG_SESSION_TYPE/WAYLAND_DISPLAY, konkluderer "Wayland", og
  # kaller eglGetPlatformDisplay(EGL_PLATFORM_WAYLAND_KHR, <X11 Display*>) i
  # OpenGL-deteksjonen. NVIDIA sin wayland2 EGL-platform tolker Xlib-pekeren
  # som wl_display -> SIGSEGV i wl_proxy_create_wrapper. wfica er X11-only,
  # saa vi later som sesjonen er X11.
  #
  # EGL_PLATFORM maa settes eksplisitt: Chrome setter EGL_PLATFORM=wayland i
  # sitt eget miljoe (Ozone), og .ica-filer aapnes som barneprosess av Chrome.
  # Den arvede verdien velger wayland2-platformen uansett hva de to andre
  # variablene sier.
  citrix-workspace-nixly = prev.citrix-workspace-nixly.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ final.makeWrapper ];
    postFixup = (old.postFixup or "") + ''
      for prog in wfica selfservice storebrowse conncenter configmgr; do
        wrapProgram $out/bin/$prog \
          --unset WAYLAND_DISPLAY \
          --set XDG_SESSION_TYPE x11 \
          --set EGL_PLATFORM x11
      done

      # DrivePathA=$HOME eksponerer hele hjemmemappa i sesjonen, inkludert
      # alle dot-filer. CDMHideHiddenFile=1 filtrerer dem bort i CDM-listingen.
      # module.ini kopieres aldri til ~/.ICAClient (bare wfclient/appsrv/
      # All_Regions), saa denne i store er den som gjelder.
      sed -i 's/^CDMHideHiddenFile\([[:space:]]*\)=.*/CDMHideHiddenFile\1= 1/' \
        $out/opt/citrix-icaclient/config/module.ini

      # Super sender Win-tast inn i sesjonen -> Windows startmeny. Vi setter
      # allerede SuperMetaToWinKeys=False i ~/.ICAClient/wfclient.ini, men den
      # vinner ikke over module.ini her, og wfica skriver wfclient.ini paa nytt
      # ved GUI-endringer. Slaa den av i store-kopien ogsaa.
      sed -i 's/^SuperMetaToWinKeys[[:space:]]*=.*/SuperMetaToWinKeys=False/' \
        $out/opt/citrix-icaclient/config/module.ini
    '';
  });
}
