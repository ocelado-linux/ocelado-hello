//! Recommended Flathub apps.
//!
//! They are installed in the user's Flatpak installation: no polkit
//! authorization is needed (Game Mode has no agent to ask for one), and
//! Flathub is added there if missing.

use serde::Serialize;
use std::process::{Command, Stdio};

#[derive(Debug, Clone, Serialize)]
pub struct App {
    pub id: &'static str,
    pub name: &'static str,
    pub description: &'static str,
    pub category: &'static str,
    /// Shipped with Ocelado (shown as included, not installable here).
    pub bundled: bool,
}

pub const APPS: &[App] = &[
    App { id: "com.heroicgameslauncher.hgl", name: "Heroic Games Launcher", description: "Epic, GOG y Amazon", category: "Juegos de otras tiendas", bundled: false },
    App { id: "net.lutris.Lutris", name: "Lutris", description: "Juegos y lanzadores varios", category: "Juegos de otras tiendas", bundled: false },
    App { id: "com.usebottles.bottles", name: "Bottles", description: "Programas de Windows", category: "Juegos de otras tiendas", bundled: false },
    App { id: "protonplus", name: "ProtonPlus", description: "Versiones de Proton", category: "Compatibilidad", bundled: true },
    App { id: "faugus-launcher", name: "Faugus Launcher", description: "Juegos con UMU y Proton", category: "Compatibilidad", bundled: true },
    App { id: "net.retrodeck.retrodeck", name: "RetroDECK", description: "Emuladores todo en uno", category: "Emulación", bundled: false },
    App { id: "com.discordapp.Discord", name: "Discord", description: "Chat de voz y texto", category: "Comunicación y grabación", bundled: false },
    App { id: "com.obsproject.Studio", name: "OBS Studio", description: "Grabar y emitir", category: "Comunicación y grabación", bundled: false },
];

pub const FLATHUB_REPO: &str = "https://dl.flathub.org/repo/flathub.flatpakrepo";

#[derive(Debug, Clone, Serialize)]
pub struct AppState {
    #[serde(flatten)]
    pub app: App,
    pub installed: bool,
}

fn flatpak_installed(id: &str) -> bool {
    Command::new("flatpak")
        .args(["info", id])
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status()
        .map(|s| s.success())
        .unwrap_or(false)
}

pub fn app_states() -> Vec<AppState> {
    APPS.iter()
        .map(|a| AppState {
            app: a.clone(),
            installed: a.bundled || flatpak_installed(a.id),
        })
        .collect()
}

/// Runs flatpak and turns a failure into its last error line.
fn flatpak(args: &[&str]) -> Result<(), String> {
    let out = Command::new("flatpak")
        .args(args)
        .stdin(Stdio::null())
        .output()
        .map_err(|e| format!("No se pudo ejecutar flatpak: {e}"))?;
    if out.status.success() {
        return Ok(());
    }
    let stderr = String::from_utf8_lossy(&out.stderr);
    let last = stderr.lines().rev().find(|l| !l.trim().is_empty()).unwrap_or("").trim();
    Err(if last.is_empty() {
        format!("flatpak terminó con error ({})", out.status)
    } else {
        format!("flatpak: {last}")
    })
}

/// Installs from Flathub into the user installation. Blocking.
pub fn install(ids: &[String]) -> Result<(), String> {
    let ids: Vec<&str> = ids
        .iter()
        .map(String::as_str)
        .filter(|id| APPS.iter().any(|a| a.id == *id && !a.bundled))
        .collect();
    if ids.is_empty() {
        return Ok(());
    }
    flatpak(&["remote-add", "--user", "--if-not-exists", "flathub", FLATHUB_REPO])?;
    let mut args = vec!["install", "--user", "-y", "--noninteractive", "flathub"];
    args.extend(ids);
    flatpak(&args)
}
