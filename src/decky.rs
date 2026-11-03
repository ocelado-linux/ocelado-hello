//! Decky Loader status, its recommended plugins and how to install them.

use serde::Serialize;
use std::path::PathBuf;
use std::process::Command;

use crate::config::home_dir;
use crate::privileged::{self, HELPER};

/// Official one-line installer from the Decky Loader README.
pub const DECKY_INSTALL_CMD: &str =
    "curl -L https://github.com/SteamDeckHomebrew/decky-installer/releases/latest/download/install_release.sh | sh";

pub fn homebrew_dir() -> PathBuf {
    home_dir().join("homebrew")
}

pub fn is_installed() -> bool {
    homebrew_dir().join("services").join("PluginLoader").exists()
}

/// A recommended plugin.
///
/// `installable` plugins are downloaded by the root helper from a fixed
/// source (the helper has its own list, so nothing else can be installed
/// through it). The others are only recommended: they are installed from
/// the Decky store inside Game Mode.
#[derive(Debug, Clone, Serialize)]
pub struct Plugin {
    pub id: &'static str,
    /// Folder name under ~/homebrew/plugins (installable plugins only).
    pub folder: &'static str,
    pub name: &'static str,
    pub description: &'static str,
    /// Where it comes from, shown to the user.
    pub source: &'static str,
    pub installable: bool,
    /// Extra note (requirements), may be empty.
    pub note: &'static str,
}

pub const PLUGINS: &[Plugin] = &[
    Plugin {
        id: "unifideck",
        folder: "Unifideck",
        name: "Unifideck",
        description: "Juegos de Epic, GOG y Amazon como pestañas dentro de tu biblioteca de Steam.",
        source: "GitHub · fuera de la tienda Decky",
        installable: true,
        note: "Pide Microsoft Edge para iniciar sesión en las tiendas; el propio plugin ofrece instalarlo.",
    },
    Plugin {
        id: "css-loader",
        folder: "",
        name: "CSS Loader",
        description: "Temas para la interfaz del Modo Juego.",
        source: "Tienda de Decky",
        installable: false,
        note: "",
    },
    Plugin {
        id: "steamgriddb",
        folder: "",
        name: "SteamGridDB",
        description: "Carátulas y fondos para juegos que no son de Steam.",
        source: "Tienda de Decky",
        installable: false,
        note: "",
    },
    Plugin {
        id: "protondb-badges",
        folder: "",
        name: "ProtonDB Badges",
        description: "Nota de compatibilidad en la ficha de cada juego.",
        source: "Tienda de Decky",
        installable: false,
        note: "",
    },
];

#[derive(Debug, Clone, Serialize)]
pub struct PluginState {
    #[serde(flatten)]
    pub plugin: Plugin,
    pub installed: bool,
}

pub fn plugin_states() -> Vec<PluginState> {
    let plugins_dir = homebrew_dir().join("plugins");
    PLUGINS
        .iter()
        .map(|p| PluginState {
            plugin: p.clone(),
            installed: !p.folder.is_empty() && plugins_dir.join(p.folder).exists(),
        })
        .collect()
}

/// Runs the official installer in a terminal so the user sees its output and
/// can answer the sudo prompt. Only possible from the desktop session.
pub fn install_loader_in_terminal() -> Result<(), String> {
    let script = format!("{DECKY_INSTALL_CMD}; echo; read -p 'Pulsa Intro para cerrar' _");
    Command::new("konsole")
        .args(["-e", "sh", "-c", &script])
        .spawn()
        .map(|_| ())
        .map_err(|e| format!("No se pudo abrir Konsole: {e}"))
}

/// Installs catalog plugins through the polkit helper. Blocking.
pub fn install_plugins(ids: &[String]) -> Result<(), String> {
    for id in ids {
        if !PLUGINS.iter().any(|p| p.id == id && p.installable) {
            return Err(format!("Este plugin no se puede instalar desde aquí: {id}"));
        }
    }
    let mut args = vec!["install-plugins"];
    args.extend(ids.iter().map(String::as_str));
    privileged::run(HELPER, &args).map(|_| ())
}
