# ocelado-hello

Welcome app for [Ocelado Linux](https://github.com/ocelado-linux). It greets
the user after installing and keeps the common settings in one place.

It only runs on the desktop (Plasma): it opens when the user enters the
desktop, never in Game Mode. It has two layouts:

- **Desktop** (Desktop editions): a window with a sidebar.
- **Handheld** (Deck and Handheld editions, in Desktop Mode): full screen at
  1280×800, driven by a controller (d-pad or left stick to move, A to select,
  B to go back, L1/R1 to change section).

Written in Rust with Qt 6 / QML through [CXX-Qt](https://github.com/KDAB/cxx-qt).
The interface is in Spanish for now.

## Sections

| Section | What it does |
|---|---|
| Bienvenida | Edition, version, kernel and device; first steps |
| Actualizaciones | `transactional-update dup`, Flatpak updates, background updates (timer), snapper snapshots and rollback |
| Kernel y arranque | Running kernel (OGC or linux-tkg), reboot into the other one, session at power-on (last / Game Mode / Desktop) |
| Almacenamiento | Disks, usage and Steam libraries; prepare a microSD/USB disk for games (ext4), eject |
| Decky | Install or update Decky Loader (official installer, shows installed and latest version) and recommended plugins: Unifideck from GitHub, the rest from the Decky store (hash checked) |
| Mandos y hardware | Bluetooth pairing, button test, fan and temperatures |
| Aplicaciones | Recommended Flathub apps, installed in one go in the user's Flatpak installation (no password; Flathub added if missing) |
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

- `--autostart`: used by `/etc/xdg/autostart/ocelado-hello.desktop`
  (`OnlyShowIn=KDE`), so it runs when entering the Plasma desktop. Opens the
  assistant the first time, then follows the "open at login" setting. Inside
  a gamescope (Game Mode) session it exits without opening anything.
- Without `--desktop`/`--handheld` the handheld layout is used on the editions
  with Game Mode (Deck, Handheld) and the desktop one on Desktop editions.
- Pages: `welcome`, `updates`, `kernel`, `storage`, `decky`, `controllers`,
  `apps`, `help`, `wizard`.

User settings: `~/.config/ocelado-hello/config.toml`.

## Privileges

The app runs as the user. System changes go through two small root helpers
started with `pkexec`, each with a polkit action:

| Helper | polkit action | Does |
|---|---|---|
| `ocelado-hello-query` | `org.ocelado.hello.query` | list snapshots |
| `ocelado-hello-helper` | `org.ocelado.hello.manage` | update, rollback, background updates, session at power-on, next kernel, format a microSD/USB disk, install/update Decky, install listed Decky plugins |

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
crates (OBS builds without network).

### Publishing to OBS

The [`Publish to OBS`](.github/workflows/obs.yml) workflow does it from
GitHub, in an openSUSE container:

- **Push a tag** (`git tag v0.2.0 && git push origin v0.2.0`): that version
  goes to `home:Luthenis:ogc-handheld/ocelado-hello`.
- **Actions → Publish to OBS → Run workflow**: sends the current `main`.

It needs the `OBS_USER` and `OBS_PASSWORD` secrets (repository or
organization). It creates the OBS package the first time, runs the source
services (`osc service manualrun`) and commits the spec, the source tarball
and `vendor.tar.zst`.

### Development

- `OCELADO_HELLO_LIBEXEC=/path` runs the helpers from another folder (pkexec
  still needs the policy installed).
- `OCELADO_HELLO_SCREENSHOT=/tmp/shot.png ocelado-hello --handheld` saves a
  screenshot after start-up and quits.
- `OCELADO_HELLO_NAV=down,down,accept` replays gamepad actions before the
  screenshot.
- Arrow keys, Enter and Esc act like the d-pad, A and B, and Ctrl+PgUp /
  Ctrl+PgDown like L1 / R1, so it can be tried without a controller.

### Testing L1/R1 (change section)

1. Without a controller: `OCELADO_HELLO_NAV=next,next,prev
   OCELADO_HELLO_SCREENSHOT=/tmp/shot.png ocelado-hello --handheld` must save
   Updates (the second section) as selected; or press Ctrl+PgDown / Ctrl+PgUp
   in the running app.
2. On the device, in Desktop Mode: from any page, R1 goes to the next section
   and L1 to the previous one, wrapping around at both ends.
3. *Mandos y hardware* → *Empezar la prueba*: while it runs the page takes
   every button, so L1 and R1 light up instead of changing section. **Hold B
   (1.5 s)** to end it, as on SteamOS; with a mouse, *Terminar*. If L1/R1 do
   not light up, the controller is not reaching the app (Steam's desktop
   layout keeps them), not a section problem.

### Controller

Navigation is spatial (the nearest control in that direction) and stays
inside the page or the open dialog; L1/R1 change section. In the desktop
session Steam's controller layout also sends arrow/Enter/Esc keys for the
same press: whichever arrives first is used and the other is dropped
(`cpp/helpers.h`), and a press seen from two devices (the Deck's controller
and Steam's virtual one) counts once.

## License

GPL-3.0-or-later. See [LICENSE](LICENSE).
