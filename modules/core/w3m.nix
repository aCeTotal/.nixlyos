{ ... }:

{
  config.home-manager.sharedModules = [
    ({ pkgs, ... }: {
      home.packages = with pkgs; [ w3m ];

      # ── w3m hovedconfig ──────────────────────────────────────────
      # Lagres i ~/.w3m/config (ikke XDG)
      home.file.".w3m/config".text = ''
        # Tegnsett
        display_charset UTF-8
        document_charset UTF-8
        system_charset UTF-8
        auto_detect 2

        # Visning
        color 1
        ansi_color 1
        use_mouse 1
        clear_buffer 1
        decode_cte 1
        fold_textarea 1
        display_image 0
        pseudo_inlines 1
        tabstop 4
        indent_incr 2

        # Navigasjon
        nextpage_topline 1
        label_topline 1
        emacs_like_lineedit 1
        vi_prec_num 1

        # Cookies / cache
        use_cookie 1
        accept_cookie 1
        accept_bad_cookie 0
        cookie_avoid_wrong_number_of_dots ""
        show_cookie 0

        # Tabs
        open_tab_blank 1
        open_tab_dl_list 1
        close_tab_back 1

        # Forms
        confirm_qq 0
        target_self 1

        # Nedlasting til PWD
        # SAVE_LINK ('a') prompter med PWD som default, trykk Enter for å lagre.
        # 'D' bruker ekstern wget til PWD direkte (se keymap).
        download_dir .
        decode_cte 1
        auto_uncompress 1

        # Editor / pager
        editor nvim

        # Eksterne kommandoer (kalles via M / 2 M / 3 M på link, eller EXTERN_LINK)
        # 1 = xdg-open (åpne i grafisk browser)
        # 2 = wget til PWD (last ned med originalt filnavn)
        # 3 = wl-copy (kopier URL til clipboard)
        extbrowser  sh -c 'xdg-open "%s" &'
        extbrowser2 sh -c 'wget --content-disposition -- "%s"'
        extbrowser3 sh -c 'echo -n "%s" | wl-copy'
        mailto_options 0

        # SSL
        ssl_verify_server 1
        ssl_ca_file /etc/ssl/certs/ca-certificates.crt

        # Søk
        case_sensitive 0
        wrap_search 1
      '';

      # ── Keymap (vim-like) ────────────────────────────────────────
      # Cycle links: Tab/S-Tab og C-n/C-p
      # Click link: Enter
      # Last ned: a (prompt PWD), D (auto wget til PWD)
      home.file.".w3m/keymap".text = ''
        # ── Bevegelse ───────────────────────────────────────────────
        keymap  j         MOVE_DOWN
        keymap  k         MOVE_UP
        keymap  h         MOVE_LEFT
        keymap  l         MOVE_RIGHT
        keymap  g         BEGIN
        keymap  G         END
        keymap  C-f       NEXT_PAGE
        keymap  C-b       PREV_PAGE
        keymap  C-d       NEXT_HALF_PAGE
        keymap  C-u       PREV_HALF_PAGE
        keymap  H         LINE_BEGIN
        keymap  L         LINE_END

        # ── Cycle gjennom linker ───────────────────────────────────
        keymap  TAB       NEXT_LINK
        keymap  C-n       NEXT_LINK
        keymap  ESC-TAB   PREV_LINK
        keymap  C-p       PREV_LINK

        # ── Følg link / submit form ────────────────────────────────
        keymap  RET       GOTO_LINK
        keymap  SPC       NEXT_PAGE

        # ── Historikk / navigering mellom sider ────────────────────
        keymap  u         BACK
        keymap  C-h       HISTORY
        keymap  U         GOTO
        keymap  r         RELOAD
        keymap  R         RELOAD

        # ── Søk i side ─────────────────────────────────────────────
        keymap  /         SEARCH
        keymap  ?         SEARCH_BACK
        keymap  n         SEARCH_NEXT
        keymap  N         SEARCH_PREV

        # ── Tabs ───────────────────────────────────────────────────
        keymap  t         NEW_TAB
        keymap  T         TAB_LINK
        keymap  C-w       CLOSE_TAB
        keymap  ]         NEXT_TAB
        keymap  [         PREV_TAB
        keymap  }         NEXT_TAB
        keymap  {         PREV_TAB

        # ── Nedlasting / ekstern ───────────────────────────────────
        # 'a' = SAVE_LINK (innebygd, prompter med PWD - bare Enter for å lagre)
        keymap  a         SAVE_LINK
        # 's' = SAVE (lagre nåværende side til fil)
        keymap  s         SAVE
        # 'd' = vis nedlastingskø
        keymap  d         DOWNLOAD_LIST
        # 'M' = åpne nåværende side i ekstern (extbrowser = xdg-open)
        keymap  M         EXTERN
        # Trykk '2 M' for å laste ned link med wget (extbrowser2)
        # Trykk '3 M' for å kopiere link-URL til clipboard (extbrowser3)
        # På link bruk EXTERN_LINK på samme måte med prefix-tall

        # ── Bookmarks ──────────────────────────────────────────────
        keymap  B         BOOKMARK
        keymap  M-b       ADD_BOOKMARK

        # ── Diverse ────────────────────────────────────────────────
        keymap  o         OPTIONS
        keymap  v         VIEW
        keymap  =         INFO
        keymap  C-l       REDRAW
        keymap  q         EXIT
        keymap  Q         EXIT
        keymap  :         COMMAND
        keymap  M-h       HELP

        # ── URL i utklippstavle / yank ─────────────────────────────
        keymap  y         PIPE_BUF
        keymap  Y         PIPE_SHELL
      '';

      # Mailcap: hvilket program åpner hva
      home.file.".w3m/mailcap".text = ''
        image/*;             feh %s
        video/*;             mpv %s
        audio/*;             mpv %s
        application/pdf;     zathura %s
      '';
    })
  ];
}
