# ocelado-hello

Welcome app for [Ocelado Linux](https://github.com/ocelado-linux). It greets
the user after installing and keeps the common settings in one place, with
two layouts:

- **Desktop**: a window with a sidebar, for Plasma.
- **Handheld**: full screen at 1280×800, driven by a controller (d-pad or
  left stick to move, A to select, B to go back, L1/R1 to change section).

Written in Rust with Qt 6 / QML through [CXX-Qt](https://github.com/KDAB/cxx-qt).
The interface is in Spanish for now.

## Sections

| Section | What it does |
|---|---|
| Bienvenida | Edition, version, kernel and device; first steps |
| Actualizaciones | `transactional-update dup`, Flatpak updates, background updates (timer), snapper snapshots and rollback |
| Kernel y arranque | Running kernel (OGC or linux-tkg), reboot into the other one, session at power-on (last / Game Mode / Desktop) |
| Almacenamiento | Disks, usage and Steam libraries; prepare a microSD/USB disk for games (ext4), eject |
| Decky | Install Decky Loader (official installer) and recommended plugins (Unifideck from GitHub; store plugins are listed only) |
| Mandos y hardware | Bluetooth pairing, button test, fan and temperatures |
| Aplicaciones | Recommended Flathub apps, installed in one go |
| Ayuda | Links and bug report: saves system info + logs to Downloads and opens a pre-filled GitHub issue (with a QR code for the phone) |

Decky only appears in the editions with Game Mode (Deck, Handheld).

The first time, a short assistant walks through the same steps and asks
when the app should open by itself: **always**, **only when there are news**
(default) or **never**. It can be changed later at the bottom of the sidebar.

## News ("Novedades")

After an update, the app shows what is new in that version. The text is
**not** in the code: it is read from a JSON file published on the Ocelado
website (GitHub Pages), so it can be written or fixed without a new build.

- Default URL: `https://ocelado-linux.github.io/news/novedades.json`
  (`news_url` in the config file overrides it).
- Format: see [`data/novedades.example.json`](data/novedades.example.json).
- The version is `IMAGE_VERSION` from `/usr/lib/os-release`. News are shown
  once per version; with no network, or no entry for that version, nothing
  is shown and it tries again at the next login.

## Start-up options

```
ocelado-hello [--desktop | --handheld] [--page <id>] [--autostart] [--news]
```

- `--autostart`: used by `/etc/xdg/autostart/ocelado-hello.desktop`. Opens the
  assistant the first time, then follows the "open at login" setting.
- Without `--desktop`/`--handheld` the handheld layout is used inside the
  gamescope session and the desktop one elsewhere.
- Pages: `welcome`, `updates`, `kernel`, `storage`, `decky`, `controllers`,
  `apps`, `help`, `wizard`.

User settings: `~/.config/ocelado-hello/config.toml`.

## Privileges

The app runs as the user. System changes go through two small root helpers
started with `pkexec`, each with a polkit action:

| Helper | polkit action | Does |
|---|---|---|
| `ocelado-hello-query` | `org.ocelado.hello.query` | list snapshots |
| `ocelado-hello-helper` | `org.ocelado.hello.manage` | update, rollback, background updates, session at power-on, next kernel, format a microSD/USB disk, install listed Decky plugins |

Both validate every argument and only accept a fixed set of commands. As on
SteamOS, the user at the device does not need a password (Game Mode has no
polkit agent to ask for one); set `allow_active` to `auth_admin_keep` in
`data/org.ocelado.hello.policy` to require it.

The helper relies on Ocelado's own pieces:
- session at power-on: `BOOT_SESSION` in `/etc/ogc-handheld/boot-session.conf`
  (deckifier);
- next kernel: `/var/lib/ocelado/kernel-flavor` and
  `/usr/libexec/ocelado/grub-default` (ocelado-release), then
  `transactional-update grub.cfg`.

## Building

Needs Rust ≥ 1.85, a C++ compiler, Qt 6 (base, declarative, svg), lld and
libudev.

```
make            # QMAKE=qmake6 cargo build --release
make test
sudo make install
```

`.cargo/config.toml` links with lld: CXX-Qt builds made only with Cargo do
not link with GNU ld.bfd.

openSUSE packaging (OBS) is in [`packaging/`](packaging): the spec and a
`_service` that takes the sources from this repository and vendors the
crates.

### Development

- `OCELADO_HELLO_LIBEXEC=/path` runs the helpers from another folder (pkexec
  still needs the policy installed).
- `OCELADO_HELLO_SCREENSHOT=/tmp/shot.png ocelado-hello --handheld` saves a
  screenshot after start-up and quits.
- Arrow keys and Esc act like the d-pad and B in the handheld layout, so it
  can be tried without a controller.

## License

GPL-3.0-or-later. See [LICENSE](LICENSE).
