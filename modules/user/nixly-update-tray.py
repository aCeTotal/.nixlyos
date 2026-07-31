#!/usr/bin/env python3
"""Tray-ikon som vises naar en prevalidert oppdatering ligger klar.

Viser standard update-ikon via StatusNotifierItem (samme protokoll som
nm-applet/blueman -> lik stoerrelse og avstand i nixlytile-trayen).
Klikk -> meny -> aktiverer nixly-update-apply.service (polkit-regel
lar bruker total starte den uten passord)."""

import os
import subprocess

import gi

gi.require_version("Gtk", "3.0")
gi.require_version("AyatanaAppIndicator3", "0.1")
from gi.repository import Gtk, GLib, AyatanaAppIndicator3 as AppIndicator

PENDING = "/var/lib/nixly-update/pending"

indicator = AppIndicator.Indicator.new(
    "nixly-update",
    "software-update-available",
    AppIndicator.IndicatorCategory.APPLICATION_STATUS,
)
indicator.set_title("NixlyOS-oppdatering klar")


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


def refresh():
    active = os.path.exists(PENDING)
    indicator.set_status(
        AppIndicator.IndicatorStatus.ACTIVE
        if active
        else AppIndicator.IndicatorStatus.PASSIVE
    )
    return True


refresh()
GLib.timeout_add_seconds(10, refresh)
Gtk.main()
