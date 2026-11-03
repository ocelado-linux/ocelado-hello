//! Recommended Flathub apps.

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

/// Installs from Flathub system-wide. polkit asks for the password when needed.
pub fn install(ids: &[String]) -> Result<(), String> {
    let ids: Vec<&String> = ids
        .iter()
        .filter(|id| APPS.iter().any(|a| a.id == id.as_str() && !a.bundled))
        .collect();
    if ids.is_empty() {
        return Ok(());
    }
    let status = Command::new("flatpak")
        .args(["install", "-y", "--noninteractive", "flathub"])
        .args(&ids)
        .status()
        .map_err(|e| format!("No se pudo ejecutar flatpak: {e}"))?;
    if status.success() {
        Ok(())
    } else {
        Err(format!("flatpak terminó con error ({status})"))
    }
}
