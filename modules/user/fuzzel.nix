{ pkgs, ... }:

{
  home.packages = [ pkgs.fuzzel ];

  home.file.".config/fuzzel/fuzzel.ini".text = ''
    [main]
    font=Fira Sans:weight=medium:size=13
    dpi-aware=auto
    prompt="  "
    icon-theme=Papirus-Dark
    icons-enabled=yes
    fuzzy=yes
    terminal=alacritty
    layer=overlay
    width=44
    horizontal-pad=22
    vertical-pad=18
    inner-pad=14
    line-height=26
    lines=9
    tabs=4
    placeholder=Search apps
    show-actions=no
    match-mode=fzf
    sort-result=yes
    use-bold=no

    [colors]
    background=11111bee
    text=cdd6f4ff
    prompt=00beffff
    placeholder=6c7086ff
    input=cdd6f4ff
    match=00beffff
    selection=313244ff
    selection-text=ffffffff
    selection-match=00beffff
    counter=6c7086ff
    border=00beffcc

    [border]
    width=2
    radius=14

    [dmenu]
    exit-immediately-if-empty=yes

    [key-bindings]
    cancel=Escape Control+g
    execute=Return KP_Enter
    cursor-left=Left Control+b
    cursor-right=Right Control+f
    cursor-home=Home Control+a
    cursor-end=End Control+e
    delete-prev=BackSpace
    delete-next=Delete Control+d
    next=Down Tab Control+n
    prev=Up ISO_Left_Tab Control+p
  '';
}
