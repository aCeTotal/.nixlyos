#!/usr/bin/env python3
"""Tray-ikon som vises naar en prevalidert oppdatering ligger klar.

Startes av systemd path-uniten KUN naar /var/lib/nixly-update/pending
finnes — nixlytile-trayen ignorerer SNI Status=Passive, saa prosessen
maa vaere helt av naar ingenting er klart. Avslutter selv naar pending
forsvinner; path-uniten starter den igjen neste gang flagget dukker opp.
Klikk -> meny -> aktiverer nixly-update-apply.service (polkit-regel
lar bruker total starte den uten passord)."""

import os
import subprocess
import sys

import gi

gi.require_version("Gtk", "3.0")
gi.require_version("AyatanaAppIndicator3", "0.1")
from gi.repository import Gtk, GLib, AyatanaAppIndicator3 as AppIndicator

PENDING = "/var/lib/nixly-update/pending"

if not os.path.exists(PENDING):
    sys.exit(0)

# Uten display segfaulter GTK i widget-oppretting (_gtk_settings_get_screen)
# naar path-uniten trigger foer compositoren er oppe. Exit 1 -> systemd
# restarter om 5 s.
if not Gtk.init_check()[0]:
    sys.exit(1)

indicator = AppIndicator.Indicator.new(
    "nixly-update",
    "software-update-available",
    AppIndicator.IndicatorCategory.APPLICATION_STATUS,
)
indicator.set_title("NixlyOS-oppdatering klar")
indicator.set_status(AppIndicator.IndicatorStatus.ACTIVE)


def apply_update(_item):
    subprocess.Popen(
        ["systemctl", "start", "nixly-update-apply.service"]
    )


menu = Gtk.Menu()
item = Gtk.MenuItem(label="Installer oppdatering (aktiveres ved neste boot)")
item.connect("activate", apply_update)
menu.append(item)
menu.show_all()
indicator.set_menu(menu)


def watch():
    if not os.path.exists(PENDING):
        Gtk.main_quit()
        return False
    return True


GLib.timeout_add_seconds(10, watch)
Gtk.main()
