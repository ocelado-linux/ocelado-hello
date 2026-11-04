mod apps;
mod boot;
mod bridge;
mod config;
mod decky;
mod gamepad;
mod news;
mod privileged;
mod report;
mod sensors;
mod storage;
mod system;
mod updates;

use cxx_qt_lib::{QGuiApplication, QQmlApplicationEngine, QString, QUrl};

const USAGE: &str = "\
Uso: ocelado-hello [opciones]

  --autostart        Arranque de sesión: decide según la configuración si
                     abrir la app, solo las novedades, o nada.
  --handheld         Fuerza la interfaz handheld (mando, pantalla completa).
  --desktop          Fuerza la interfaz de escritorio.
  --page <id>        Abre una sección: welcome, updates, kernel, storage,
                     decky, controllers, apps, help, wizard.
  --news             Muestra las novedades de la versión instalada.
  -h, --help         Muestra esta ayuda.
";

fn main() {
    let mut args = std::env::args().skip(1);
    let mut autostart = false;
    let mut force_handheld = None;
    let mut page = String::from("welcome");
    let mut show_news = false;
    while let Some(arg) = args.next() {
        match arg.as_str() {
            "--autostart" => autostart = true,
            "--handheld" => force_handheld = Some(true),
            "--desktop" => force_handheld = Some(false),
            "--news" => show_news = true,
            "--page" => page = args.next().unwrap_or(page),
            "-h" | "--help" => {
                print!("{USAGE}");
                return;
            }
            other => {
                eprintln!("Opción desconocida: {other}\n\n{USAGE}");
                std::process::exit(2);
            }
        }
    }

    // Ocelado Hello only runs on the desktop (Plasma): never at the start of
    // a Game Mode (gamescope) session.
    if autostart && system::in_game_mode() {
        return;
    }

    if autostart {
        let cfg = config::Config::load();
        let version = system::OsRelease::load().version();
        match config::autostart_action(&cfg, &version) {
            config::AutostartAction::Quit => return,
            config::AutostartAction::FirstRun => page = "wizard".into(),
            config::AutostartAction::Open => {}
            config::AutostartAction::CheckNews => {
                show_news = true;
                page = "news".into();
            }
        }
    }

    // Handheld layout (controller, full screen) on the editions with Game
    // Mode, also in Desktop Mode; desktop layout on Desktop editions.
    let handheld = force_handheld.unwrap_or_else(|| {
        system::in_game_mode()
            || system::Edition::detect(&system::OsRelease::load(), &system::Device::load())
                .has_game_mode()
    });
    let _ = bridge::START.set(bridge::StartOptions { handheld, start_page: page, show_news });

    // Our controls draw their own look; the Basic style keeps popups and
    // combo boxes consistent whatever Qt Quick style the desktop sets.
    if std::env::var_os("QT_QUICK_CONTROLS_STYLE").is_none() {
        // SAFETY: still single-threaded, before Qt starts.
        unsafe { std::env::set_var("QT_QUICK_CONTROLS_STYLE", "Basic") };
    }

    let mut app = QGuiApplication::new();
    if let Some(mut app) = app.as_mut() {
        app.as_mut().set_application_name(&QString::from("ocelado-hello"));
        app.as_mut().set_organization_name(&QString::from("ocelado-linux"));
    }
    bridge::qobject::set_desktop_file_name(&QString::from("ocelado-hello"));
    bridge::qobject::install_pad_key_filter();
    let mut engine = QQmlApplicationEngine::new();
    if let Some(engine) = engine.as_mut() {
        engine.load(&QUrl::from("qrc:/qt/qml/org/ocelado/hello/qml/Main.qml"));
    }
    if let Some(app) = app.as_mut() {
        app.exec();
    }
}
