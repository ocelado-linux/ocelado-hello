//! Decky Loader status, its recommended plugins and how to install them.
//! Installing goes through the root helper, so it also works in Game Mode
//! (no terminal, no password prompt).

use serde::Serialize;
use serde_json::Value;
use std::fs;
use std::path::PathBuf;
use std::time::Duration;

use crate::config::home_dir;
use crate::privileged::{self, HELPER};

pub fn homebrew_dir() -> PathBuf {
    home_dir().join("homebrew")
}

pub fn is_installed() -> bool {
    homebrew_dir().join("services").join("PluginLoader").exists()
}

/// Installed Decky version ("v3.1.3"), written by the official installer.
pub fn installed_version() -> String {
    fs::read_to_string(homebrew_dir().join("services").join(".loader.version"))
        .map(|s| s.trim().to_string())
        .unwrap_or_default()
}

/// Latest stable Decky release on GitHub, as the installer picks it.
pub fn latest_version() -> Option<String> {
    let agent: ureq::Agent = ureq::Agent::config_builder()
        .timeout_global(Some(Duration::from_secs(10)))
        .build()
        .into();
    let body = agent
        .get("https://api.github.com/repos/SteamDeckHomebrew/decky-loader/releases?per_page=20")
        .header("User-Agent", concat!("ocelado-hello/", env!("CARGO_PKG_VERSION")))
        .call()
        .ok()?
        .body_mut()
        .read_to_string()
        .ok()?;
    first_stable_tag(&body)
}

pub fn first_stable_tag(releases_json: &str) -> Option<String> {
    let releases: Value = serde_json::from_str(releases_json).ok()?;
    releases
        .as_array()?
        .iter()
        .find(|r| r.get("prerelease").and_then(Value::as_bool) == Some(false))
        .and_then(|r| r.get("tag_name")?.as_str().map(str::to_string))
}

/// A recommended plugin, installed by the root helper from a fixed source
/// (the helper has the same list, so nothing else can be installed).
#[derive(Debug, Clone, Serialize)]
pub struct Plugin {
    pub id: &'static str,
    /// `name` in its plugin.json, used to tell whether it is installed.
    pub plugin_name: &'static str,
    pub name: &'static str,
    pub description: &'static str,
    /// Where it comes from, shown to the user.
    pub source: &'static str,
    /// Extra note (requirements), may be empty.
    pub note: &'static str,
}

pub const PLUGINS: &[Plugin] = &[
    Plugin {
        id: "unifideck",
        plugin_name: "Unifideck",
        name: "Unifideck",
        description: "Juegos de Epic, GOG y Amazon como pestañas dentro de tu biblioteca de Steam.",
        source: "GitHub · fuera de la tienda Decky",
        note: "Pide Microsoft Edge para iniciar sesión en las tiendas; el propio plugin ofrece instalarlo.",
    },
    Plugin {
        id: "css-loader",
        plugin_name: "CSS Loader",
        name: "CSS Loader",
        description: "Temas para la interfaz del Modo Juego.",
        source: "Tienda de Decky",
        note: "",
    },
    Plugin {
        id: "steamgriddb",
        plugin_name: "SteamGridDB",
        name: "SteamGridDB",
        description: "Carátulas y fondos para juegos que no son de Steam.",
        source: "Tienda de Decky",
        note: "",
    },
    Plugin {
        id: "protondb-badges",
        plugin_name: "ProtonDB Badges",
        name: "ProtonDB Badges",
        description: "Nota de compatibilidad en la ficha de cada juego.",
        source: "Tienda de Decky",
        note: "",
    },
];

#[derive(Debug, Clone, Serialize)]
pub struct PluginState {
    #[serde(flatten)]
    pub plugin: Plugin,
    pub installed: bool,
}

/// Names (from plugin.json) of the plugins in ~/homebrew/plugins.
pub fn installed_plugin_names() -> Vec<String> {
    fs::read_dir(homebrew_dir().join("plugins"))
        .into_iter()
        .flatten()
        .flatten()
        .filter_map(|e| fs::read_to_string(e.path().join("plugin.json")).ok())
        .filter_map(|text| serde_json::from_str::<Value>(&text).ok())
        .filter_map(|v| v.get("name")?.as_str().map(str::to_string))
        .collect()
}

pub fn plugin_states() -> Vec<PluginState> {
    let names = installed_plugin_names();
    PLUGINS
        .iter()
        .map(|p| PluginState {
            plugin: p.clone(),
            installed: names.iter().any(|n| n.eq_ignore_ascii_case(p.plugin_name)),
        })
        .collect()
}

/// Installs or updates Decky Loader with the official installer, as root.
/// Blocking.
pub fn install_loader() -> Result<(), String> {
    privileged::run(HELPER, &["install-decky"]).map(|_| ())
}

/// Installs catalog plugins through the root helper. Blocking.
pub fn install_plugins(ids: &[String]) -> Result<(), String> {
    for id in ids {
        if !PLUGINS.iter().any(|p| p.id == id) {
            return Err(format!("Este plugin no se puede instalar desde aquí: {id}"));
        }
    }
    let mut args = vec!["install-plugins"];
    args.extend(ids.iter().map(String::as_str));
    privileged::run(HELPER, &args).map(|_| ())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn picks_first_stable_release() {
        let json = r#"[{"tag_name":"v3.2.0-pre1","prerelease":true},{"tag_name":"v3.1.3","prerelease":false},{"tag_name":"v3.1.2","prerelease":false}]"#;
        assert_eq!(first_stable_tag(json).as_deref(), Some("v3.1.3"));
        assert_eq!(first_stable_tag("[]"), None);
    }
}
