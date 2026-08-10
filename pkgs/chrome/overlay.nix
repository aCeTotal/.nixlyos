final: prev: {
  # Chrome blir hard-killet naar wayland-sesjonen avsluttes, saa exit_type i
  # Preferences blir staaende "Crashed" og "Restore pages?"-bobla dukker opp
  # ved hver oppstart. Flaggene skrur av bobla permanent.
  google-chrome = prev.google-chrome.override {
    commandLineArgs = "--hide-crash-restore-bubble --disable-session-crashed-bubble --no-default-browser-check";
  };
}
