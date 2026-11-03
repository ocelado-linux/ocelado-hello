//! The `Backend` QObject that the QML interface talks to.
//!
//! Lists (plugins, apps, snapshots, disks…) are passed to QML as JSON
//! strings and parsed there with `JSON.parse`; it keeps the bridge small.
//! Anything slow or privileged runs on a worker thread and reports back with
//! `action_done`.

use std::pin::Pin;
use std::sync::OnceLock;

use cxx_qt::{CxxQtType, Threading};
use cxx_qt_lib::QString;

use crate::{apps, boot, config, decky, gamepad, news, report, sensors, storage, system, updates};

#[cxx_qt::bridge]
pub mod qobject {
    unsafe extern "C++" {
        include!("cxx-qt-lib/qstring.h");
        type QString = cxx_qt_lib::QString;

        include!("helpers.h");
        /// Wayland app_id and window icon; must match the .desktop file.
        #[rust_name = "set_desktop_file_name"]
        fn setDesktopFileName(name: &QString);
    }

    // QML sees camelCase names: news_available → newsAvailable
    #[auto_cxx_name]
    extern "RustQt" {
        #[qobject]
        #[qml_element]
        #[qml_singleton]
        // System
        #[qproperty(QString, os_name)]
        #[qproperty(QString, version)]
        #[qproperty(QString, edition_id)]
        #[qproperty(QString, edition_name)]
        #[qproperty(bool, game_mode_edition)]
        #[qproperty(bool, in_game_mode)]
        #[qproperty(QString, device_name)]
        #[qproperty(bool, steam_deck)]
        #[qproperty(QString, kernel_release)]
        #[qproperty(QString, kernel_flavor)]
        #[qproperty(i32, cpu_level)]
        // Interface
        #[qproperty(bool, handheld)]
        #[qproperty(QString, start_page)]
        #[qproperty(bool, first_run)]
        #[qproperty(QString, autostart_mode)]
        #[qproperty(bool, busy)]
        #[qproperty(QString, busy_text)]
        // Updates and snapshots
        #[qproperty(QString, snapshots_json)]
        #[qproperty(bool, snapshots_loaded)]
        #[qproperty(bool, auto_updates)]
        #[qproperty(bool, reboot_pending)]
        // Kernel and boot
        #[qproperty(QString, boot_session)]
        #[qproperty(QString, kernels_json)]
        // Storage and hardware
        #[qproperty(QString, disks_json)]
        #[qproperty(QString, sensors_json)]
        // Decky and apps
        #[qproperty(bool, decky_installed)]
        #[qproperty(QString, plugins_json)]
        #[qproperty(QString, apps_json)]
        // News
        #[qproperty(bool, news_available)]
        #[qproperty(QString, news_json)]
        // Bug report
        #[qproperty(QString, report_path)]
        #[qproperty(QString, report_url)]
        #[qproperty(QString, report_qr)]
        // Development: save a screenshot here after start-up and quit
        // (OCELADO_HELLO_SCREENSHOT=/path/shot.png).
        #[qproperty(QString, screenshot_path)]
        type Backend = super::BackendRust;

        /// Reloads Decky, plugin, app, kernel and disk states.
        #[qinvokable]
        fn refresh(self: Pin<&mut Backend>);
        #[qinvokable]
        fn set_autostart(self: Pin<&mut Backend>, mode: &QString);
        #[qinvokable]
        fn finish_first_run(self: Pin<&mut Backend>);

        // Updates
        #[qinvokable]
        fn load_snapshots(self: Pin<&mut Backend>);
        #[qinvokable]
        fn update_system(self: Pin<&mut Backend>);
        #[qinvokable]
        fn update_apps(self: Pin<&mut Backend>);
        #[qinvokable]
        fn rollback(self: Pin<&mut Backend>, number: i32);
        #[qinvokable]
        fn change_auto_updates(self: Pin<&mut Backend>, on: bool);
        #[qinvokable]
        fn reboot(self: Pin<&mut Backend>);

        // Kernel and boot
        #[qinvokable]
        fn change_boot_session(self: Pin<&mut Backend>, mode: &QString);
        #[qinvokable]
        fn reboot_into_kernel(self: Pin<&mut Backend>, flavor: &QString);

        // Storage and hardware
        #[qinvokable]
        fn refresh_storage(self: Pin<&mut Backend>);
        #[qinvokable]
        fn format_disk(self: Pin<&mut Backend>, path: &QString);
        #[qinvokable]
        fn eject_disk(self: Pin<&mut Backend>, path: &QString);
        #[qinvokable]
        fn refresh_sensors(self: Pin<&mut Backend>);
        #[qinvokable]
        fn open_bluetooth_settings(self: Pin<&mut Backend>);

        // Decky and apps
        #[qinvokable]
        fn install_decky(self: Pin<&mut Backend>);
        /// `ids_json`: JSON array of plugin ids.
        #[qinvokable]
        fn install_plugins(self: Pin<&mut Backend>, ids_json: &QString);
        /// `ids_json`: JSON array of Flatpak app ids.
        #[qinvokable]
        fn install_apps(self: Pin<&mut Backend>, ids_json: &QString);

        // Help and news
        #[qinvokable]
        fn create_report(self: Pin<&mut Backend>, description: &QString, journal: bool, decky: bool);
        #[qinvokable]
        fn check_news(self: Pin<&mut Backend>);
        #[qinvokable]
        fn mark_news_seen(self: Pin<&mut Backend>);
        #[qinvokable]
        fn switch_to_game_mode(self: Pin<&mut Backend>);

        /// A gamepad navigation action ("up", "down", "left", "right",
        /// "accept", "back", "x", "y", "prev", "next").
        #[qsignal]
        fn gamepad(self: Pin<&mut Backend>, action: QString);
        /// Any gamepad button pressed, by name ("A", "L1"…), for the test.
        #[qsignal]
        fn button_event(self: Pin<&mut Backend>, name: QString);
        /// A long action finished.
        #[qsignal]
        fn action_done(self: Pin<&mut Backend>, ok: bool, message: QString);
    }

    impl cxx_qt::Threading for Backend {}
    impl cxx_qt::Initialize for Backend {}
}

/// Options decided in main() before the QML engine starts.
#[derive(Debug, Clone, Default)]
pub struct StartOptions {
    pub handheld: bool,
    pub start_page: String,
    pub show_news: bool,
}

pub static START: OnceLock<StartOptions> = OnceLock::new();

#[derive(Default)]
pub struct BackendRust {
    os_name: QString,
    version: QString,
    edition_id: QString,
    edition_name: QString,
    game_mode_edition: bool,
    in_game_mode: bool,
    device_name: QString,
    steam_deck: bool,
    kernel_release: QString,
    kernel_flavor: QString,
    cpu_level: i32,
    handheld: bool,
    start_page: QString,
    first_run: bool,
    autostart_mode: QString,
    busy: bool,
    busy_text: QString,
    snapshots_json: QString,
    snapshots_loaded: bool,
    auto_updates: bool,
    reboot_pending: bool,
    boot_session: QString,
    kernels_json: QString,
    disks_json: QString,
    sensors_json: QString,
    decky_installed: bool,
    plugins_json: QString,
    apps_json: QString,
    news_available: bool,
    news_json: QString,
    report_path: QString,
    report_url: QString,
    report_qr: QString,
    screenshot_path: QString,

    config: config::Config,
}

fn qs(s: impl AsRef<str>) -> QString {
    QString::from(s.as_ref())
}

fn to_json<T: serde::Serialize>(value: &T) -> QString {
    qs(serde_json::to_string(value).unwrap_or_else(|_| "[]".into()))
}

fn parse_ids(json: &QString) -> Vec<String> {
    serde_json::from_str(&json.to_string()).unwrap_or_default()
}

impl cxx_qt::Initialize for qobject::Backend {
    fn initialize(mut self: Pin<&mut Self>) {
        let os = system::OsRelease::load();
        let device = system::Device::load();
        let edition = system::Edition::detect(&os, &device);
        let kernel = system::kernel_release();
        let flavor = system::KernelFlavor::from_release(&kernel);
        let config = config::Config::load();
        let start = START.get().cloned().unwrap_or_default();

        self.as_mut()
            .set_os_name(qs(os.get("NAME").unwrap_or("Ocelado Linux")));
        self.as_mut().set_version(qs(os.version()));
        self.as_mut().set_edition_id(qs(edition.id()));
        self.as_mut().set_edition_name(qs(edition.display_name()));
        self.as_mut().set_game_mode_edition(edition.has_game_mode());
        self.as_mut().set_in_game_mode(system::in_game_mode());
        self.as_mut().set_device_name(qs(device.display_name()));
        self.as_mut().set_steam_deck(device.is_steam_deck());
        self.as_mut().set_kernel_release(qs(&kernel));
        self.as_mut().set_kernel_flavor(qs(flavor.id()));
        self.as_mut().set_cpu_level(system::x86_64_level().unwrap_or(0) as i32);
        self.as_mut().set_handheld(start.handheld);
        self.as_mut().set_start_page(qs(&start.start_page));
        self.as_mut().set_first_run(!config.first_run_done);
        self.as_mut().set_autostart_mode(qs(config.autostart.as_str()));
        self.as_mut().set_snapshots_json(qs("[]"));
        self.as_mut().set_disks_json(qs("[]"));
        self.as_mut().set_apps_json(qs("[]"));
        self.as_mut().set_sensors_json(qs("{}"));
        self.as_mut().rust_mut().config = config;
        if let Ok(path) = std::env::var("OCELADO_HELLO_SCREENSHOT") {
            self.as_mut().set_screenshot_path(qs(path));
        }

        self.as_mut().refresh();
        if start.show_news {
            self.as_mut().check_news();
        }

        let thread = self.qt_thread();
        gamepad::spawn(move |event| {
            let _ = thread.queue(move |obj| match event {
                gamepad::Event::Nav(action) => obj.gamepad(QString::from(action)),
                gamepad::Event::Button(name) => obj.button_event(QString::from(name)),
            });
        });
    }
}

impl qobject::Backend {
    fn start_busy(mut self: Pin<&mut Self>, text: &str) {
        self.as_mut().set_busy_text(qs(text));
        self.as_mut().set_busy(true);
    }

    fn finish(self: Pin<&mut Self>, result: Result<(), String>, ok_message: &str) {
        let mut this = self;
        this.as_mut().set_busy(false);
        this.as_mut().set_busy_text(QString::default());
        match result {
            Ok(()) => this.action_done(true, qs(ok_message)),
            Err(e) => this.action_done(false, qs(e)),
        }
    }

    /// Runs `work` on a worker thread, then `done` on the GUI thread.
    fn spawn_task<T: Send + 'static>(
        mut self: Pin<&mut Self>,
        busy_text: &str,
        work: impl FnOnce() -> T + Send + 'static,
        done: impl FnOnce(Pin<&mut Self>, T) + Send + 'static,
    ) {
        if !busy_text.is_empty() {
            self.as_mut().start_busy(busy_text);
        }
        let thread = self.qt_thread();
        std::thread::spawn(move || {
            let result = work();
            let _ = thread.queue(move |obj| done(obj, result));
        });
    }

    pub fn refresh(mut self: Pin<&mut Self>) {
        self.as_mut().set_decky_installed(decky::is_installed());
        self.as_mut().set_plugins_json(to_json(&decky::plugin_states()));
        self.as_mut().set_boot_session(qs(boot::boot_session()));
        self.as_mut().set_kernels_json(to_json(&boot::installed_kernels()));
        self.as_mut().refresh_sensors();
        // flatpak, lsblk and systemctl take a moment: off the GUI thread.
        self.spawn_task(
            "",
            || {
                (
                    to_json_string(&apps::app_states()),
                    to_json_string(&storage::disks()),
                    updates::auto_updates_enabled(),
                )
            },
            |mut obj, (apps, disks, auto)| {
                obj.as_mut().set_apps_json(qs(apps));
                obj.as_mut().set_disks_json(qs(disks));
                obj.as_mut().set_auto_updates(auto);
            },
        );
    }

    pub fn set_autostart(mut self: Pin<&mut Self>, mode: &QString) {
        let Some(mode) = config::AutostartMode::parse(&mode.to_string()) else {
            return;
        };
        self.as_mut().rust_mut().config.autostart = mode;
        let _ = self.rust().config.save();
        self.as_mut().set_autostart_mode(qs(mode.as_str()));
    }

    pub fn finish_first_run(mut self: Pin<&mut Self>) {
        let version = self.version().to_string();
        {
            let mut rust = self.as_mut().rust_mut();
            rust.config.first_run_done = true;
            // The news for the installed version are not "new" any more.
            rust.config.last_news_version = version;
        }
        let _ = self.rust().config.save();
        self.as_mut().set_first_run(false);
    }

    // ---- Updates ----

    pub fn load_snapshots(self: Pin<&mut Self>) {
        self.spawn_task("", updates::list_snapshots, |mut obj, result| match result {
            Ok(snaps) => {
                obj.as_mut().set_reboot_pending(updates::reboot_pending(&snaps));
                obj.as_mut().set_snapshots_json(to_json(&snaps));
                obj.as_mut().set_snapshots_loaded(true);
            }
            Err(e) => obj.action_done(false, qs(e)),
        });
    }

    pub fn update_system(self: Pin<&mut Self>) {
        self.spawn_task(
            "Actualizando el sistema… puede tardar varios minutos.",
            || updates::update_system().and_then(|_| updates::update_flatpaks()),
            |mut obj, result| {
                let ok = result.is_ok();
                obj.as_mut().finish(result, "Actualización preparada. Reinicia para aplicarla.");
                if ok {
                    obj.as_mut().set_reboot_pending(true);
                    obj.load_snapshots();
                }
            },
        );
    }

    pub fn update_apps(self: Pin<&mut Self>) {
        self.spawn_task("Actualizando las apps…", updates::update_flatpaks, |obj, result| {
            obj.finish(result, "Apps actualizadas.");
        });
    }

    pub fn rollback(self: Pin<&mut Self>, number: i32) {
        let Ok(number) = u64::try_from(number) else { return };
        self.spawn_task(
            "Preparando la vuelta atrás…",
            move || updates::rollback(number),
            |mut obj, result| {
                let ok = result.is_ok();
                obj.as_mut().finish(result, "Listo. Reinicia para volver a esa instantánea.");
                if ok {
                    obj.as_mut().set_reboot_pending(true);
                    obj.load_snapshots();
                }
            },
        );
    }

    pub fn change_auto_updates(self: Pin<&mut Self>, on: bool) {
        self.spawn_task(
            "",
            move || updates::set_auto_updates(on),
            move |mut obj, result| {
                match result {
                    Ok(()) => obj.as_mut().set_auto_updates(on),
                    Err(e) => {
                        // Put the switch back where it was.
                        let current = updates::auto_updates_enabled();
                        obj.as_mut().set_auto_updates(current);
                        obj.action_done(false, qs(e));
                    }
                }
            },
        );
    }

    pub fn reboot(self: Pin<&mut Self>) {
        if let Err(e) = updates::reboot() {
            self.action_done(false, qs(e));
        }
    }

    // ---- Kernel and boot ----

    pub fn change_boot_session(self: Pin<&mut Self>, mode: &QString) {
        let mode = mode.to_string();
        self.spawn_task(
            "",
            move || boot::set_boot_session(&mode),
            |mut obj, result| {
                obj.as_mut().set_boot_session(qs(boot::boot_session()));
                if let Err(e) = result {
                    obj.action_done(false, qs(e));
                }
            },
        );
    }

    pub fn reboot_into_kernel(self: Pin<&mut Self>, flavor: &QString) {
        let flavor = flavor.to_string();
        self.spawn_task("Preparando el reinicio…", move || boot::reboot_into(&flavor), |obj, result| {
            obj.finish(result, "Reiniciando…");
        });
    }

    // ---- Storage and hardware ----

    pub fn refresh_storage(self: Pin<&mut Self>) {
        self.spawn_task("", storage::disks, |mut obj, disks| {
            obj.as_mut().set_disks_json(to_json(&disks));
        });
    }

    pub fn format_disk(self: Pin<&mut Self>, path: &QString) {
        let path = path.to_string();
        self.spawn_task(
            "Formateando… no saques la tarjeta.",
            move || storage::format_for_games(&path),
            |mut obj, result| {
                let message = match &result {
                    Ok(mp) if !mp.is_empty() => format!(
                        "Lista y montada en {mp}. Añádela en Steam: Ajustes › Almacenamiento › Añadir unidad."
                    ),
                    _ => "Lista. Añádela en Steam: Ajustes › Almacenamiento › Añadir unidad.".to_string(),
                };
                obj.as_mut().finish(result.map(|_| ()), &message);
                obj.refresh_storage();
            },
        );
    }

    pub fn eject_disk(self: Pin<&mut Self>, path: &QString) {
        let path = path.to_string();
        self.spawn_task("", move || storage::eject(&path), |mut obj, result| {
            obj.as_mut().finish(result, "Ya puedes sacarla.");
            obj.refresh_storage();
        });
    }

    pub fn refresh_sensors(self: Pin<&mut Self>) {
        self.set_sensors_json(to_json(&sensors::read()));
    }

    pub fn open_bluetooth_settings(self: Pin<&mut Self>) {
        let result = std::process::Command::new("systemsettings")
            .arg("kcm_bluetooth")
            .spawn()
            .map(|_| ())
            .map_err(|e| format!("No se pudo abrir los ajustes de Bluetooth: {e}"));
        if let Err(e) = result {
            self.action_done(false, qs(e));
        }
    }

    // ---- Decky and apps ----

    pub fn install_decky(mut self: Pin<&mut Self>) {
        if *self.in_game_mode() {
            self.action_done(
                false,
                qs("Decky se instala desde el Modo Escritorio: allí se abre un terminal con el instalador oficial."),
            );
            return;
        }
        let result = decky::install_loader_in_terminal();
        self.as_mut().finish(result, "Instalador de Decky abierto en Konsole. Al terminar, vuelve al Modo Juego.");
    }

    pub fn install_plugins(self: Pin<&mut Self>, ids_json: &QString) {
        let ids = parse_ids(ids_json);
        if ids.is_empty() {
            return;
        }
        self.spawn_task(
            "Instalando módulos…",
            move || decky::install_plugins(&ids),
            |mut obj, result| {
                obj.as_mut().refresh();
                obj.finish(result, "Módulos instalados. Aparecen en el menú de acceso rápido (···).");
            },
        );
    }

    pub fn install_apps(self: Pin<&mut Self>, ids_json: &QString) {
        let ids = parse_ids(ids_json);
        if ids.is_empty() {
            return;
        }
        self.spawn_task(
            "Instalando apps desde Flathub…",
            move || apps::install(&ids),
            |mut obj, result| {
                obj.as_mut().refresh();
                obj.finish(result, "Aplicaciones instaladas.");
            },
        );
    }

    // ---- Help and news ----

    fn summary(&self) -> report::SystemSummary {
        let mut lines = vec![
            ("Sistema".to_string(), format!("{} {}", self.os_name(), self.version())),
            ("Edición".to_string(), self.edition_name().to_string()),
            ("Dispositivo".to_string(), self.device_name().to_string()),
            ("Kernel".to_string(), self.kernel_release().to_string()),
            (
                "Sesión".to_string(),
                if *self.in_game_mode() { "Modo Juego" } else { "Escritorio" }.to_string(),
            ),
        ];
        if *self.game_mode_edition() {
            lines.push((
                "Decky".to_string(),
                if *self.decky_installed() { "instalado" } else { "no instalado" }.to_string(),
            ));
        }
        report::SystemSummary { lines }
    }

    pub fn create_report(self: Pin<&mut Self>, description: &QString, journal: bool, decky: bool) {
        let summary = self.summary();
        let description = description.to_string();
        self.spawn_task(
            "Preparando el informe…",
            move || report::create(&description, &summary, journal, decky),
            |mut obj, result| match result {
                Ok(r) => {
                    obj.as_mut().set_report_path(qs(r.path.display().to_string()));
                    obj.as_mut().set_report_url(qs(&r.issue_url));
                    obj.as_mut().set_report_qr(qs(&r.qr_svg));
                    obj.finish(Ok(()), "Informe guardado.");
                }
                Err(e) => obj.finish(Err(e), ""),
            },
        );
    }

    pub fn check_news(self: Pin<&mut Self>) {
        let url = self.rust().config.news_url.clone();
        let version = self.version().to_string();
        self.spawn_task(
            "",
            // No network or no news for this version: show nothing and try
            // again at the next login (the version is not marked as seen).
            move || news::fetch(&url).ok().and_then(|file| file.for_version(&version).cloned()),
            |mut obj, release| {
                if let Some(release) = release {
                    obj.as_mut().set_news_json(to_json(&release));
                    obj.as_mut().set_news_available(true);
                } else if START.get().is_some_and(|s| s.show_news && s.start_page == "news") {
                    // Started at login only to show news, and there are none.
                    std::process::exit(0);
                }
            },
        );
    }

    pub fn mark_news_seen(mut self: Pin<&mut Self>) {
        let version = self.version().to_string();
        self.as_mut().rust_mut().config.last_news_version = version;
        let _ = self.rust().config.save();
        self.as_mut().set_news_available(false);
    }

    pub fn switch_to_game_mode(self: Pin<&mut Self>) {
        // Same command as SteamOS; on Ocelado it comes with deckifier.
        let result = std::process::Command::new("steamos-session-select")
            .arg("gamescope")
            .spawn()
            .map(|_| ())
            .map_err(|e| format!("No se pudo cambiar al Modo Juego: {e}"));
        if let Err(e) = result {
            self.action_done(false, qs(e));
        }
    }
}

fn to_json_string<T: serde::Serialize>(value: &T) -> String {
    serde_json::to_string(value).unwrap_or_else(|_| "[]".into())
}
