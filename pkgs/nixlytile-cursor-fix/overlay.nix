final: prev: {
  # Fix: musepeker forsvinner i spill (Nvidia CPU-cursor-modus).
  # cpu_cursor_buf gjenbrukes for alle cursor-bilder; wlr_cursor_set_buffer()
  # early-returner ved samme buffer+hotspot+scale, så DRM-cursorplanet beholder
  # forrige (gjennomsiktige) bilde. Patchen kaller wlr_cursor_unset_image()
  # først så oppdateringen alltid går gjennom. Fjern når fiksen er tatt inn
  # oppstrøms i nixlypkgs/nixlytile.
  nixlytile = prev.nixlytile.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ./cpu-cursor-stale-snapshot.patch ];
  });
}
