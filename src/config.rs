//! User settings, stored in `$XDG_CONFIG_HOME/ocelado-hello/config.toml`.

use serde::{Deserialize, Serialize};
use std::fs;
use std::path::PathBuf;

/// URL of the news file published on the Ocelado website (GitHub Pages).
/// Can be overridden in config.toml with `news_url`.
pub const DEFAULT_NEWS_URL: &str = "https://ocelado-linux.github.io/news/novedades.json";

/// When ocelado-hello opens by itself at login.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, Default)]
#[serde(rename_all = "lowercase")]
pub enum AutostartMode {
    /// Every login.
    Always,
    /// Only after an update that brings news.
    #[default]
    News,
    /// Never; the user opens it from the app menu.
    Never,
}

impl AutostartMode {
    pub fn as_str(self) -> &'static str {
        match self {
            AutostartMode::Always => "always",
            AutostartMode::News => "news",
            AutostartMode::Never => "never",
        }
    }

    pub fn parse(s: &str) -> Option<Self> {
        match s {
            "always" => Some(AutostartMode::Always),
            "news" => Some(AutostartMode::News),
            "never" => Some(AutostartMode::Never),
            _ => None,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(default)]
pub struct Config {
    pub autostart: AutostartMode,
    /// Set once the first-boot assistant has been completed.
    pub first_run_done: bool,
    /// Last Ocelado version whose news were shown.
    pub last_news_version: String,
    pub news_url: String,
}

impl Default for Config {
    fn default() -> Self {
        Self {
            autostart: AutostartMode::default(),
            first_run_done: false,
            last_news_version: String::new(),
            news_url: DEFAULT_NEWS_URL.to_string(),
        }
    }
}

pub fn config_dir() -> PathBuf {
    let base = std::env::var_os("XDG_CONFIG_HOME")
        .map(PathBuf::from)
        .filter(|p| p.is_absolute())
        .unwrap_or_else(|| home_dir().join(".config"));
    base.join("ocelado-hello")
}

pub fn home_dir() -> PathBuf {
    std::env::var_os("HOME").map(PathBuf::from).unwrap_or_else(|| PathBuf::from("/"))
}

impl Config {
    pub fn path() -> PathBuf {
        config_dir().join("config.toml")
    }

    pub fn load() -> Self {
        fs::read_to_string(Self::path())
            .ok()
            .and_then(|text| toml::from_str(&text).ok())
            .unwrap_or_default()
    }

    pub fn save(&self) -> std::io::Result<()> {
        fs::create_dir_all(config_dir())?;
        let text = toml::to_string_pretty(self).map_err(std::io::Error::other)?;
        fs::write(Self::path(), text)
    }
}

/// What to do when started by the autostart entry (`--autostart`).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum AutostartAction {
    /// Open the first-boot assistant.
    FirstRun,
    /// Open the app normally.
    Open,
    /// Check the news file; open only if there are news for this version.
    CheckNews,
    /// Exit without showing anything.
    Quit,
}

pub fn autostart_action(config: &Config, current_version: &str) -> AutostartAction {
    if !config.first_run_done {
        return AutostartAction::FirstRun;
    }
    match config.autostart {
        AutostartMode::Always => AutostartAction::Open,
        AutostartMode::Never => AutostartAction::Quit,
        AutostartMode::News => {
            if !current_version.is_empty() && current_version != config.last_news_version {
                AutostartAction::CheckNews
            } else {
                AutostartAction::Quit
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn autostart_decisions() {
        let mut c = Config::default();
        assert_eq!(autostart_action(&c, "0.3"), AutostartAction::FirstRun);
        c.first_run_done = true;
        c.last_news_version = "0.3".into();
        assert_eq!(autostart_action(&c, "0.3"), AutostartAction::Quit);
        assert_eq!(autostart_action(&c, "0.4"), AutostartAction::CheckNews);
        c.autostart = AutostartMode::Always;
        assert_eq!(autostart_action(&c, "0.3"), AutostartAction::Open);
        c.autostart = AutostartMode::Never;
        assert_eq!(autostart_action(&c, "0.4"), AutostartAction::Quit);
    }

    #[test]
    fn config_roundtrip() {
        let c = Config { autostart: AutostartMode::Never, ..Default::default() };
        let text = toml::to_string_pretty(&c).unwrap();
        assert!(text.contains("autostart = \"never\""));
        let back: Config = toml::from_str(&text).unwrap();
        assert_eq!(back.autostart, AutostartMode::Never);
        // Missing keys fall back to defaults.
        let partial: Config = toml::from_str("first_run_done = true").unwrap();
        assert!(partial.first_run_done);
        assert_eq!(partial.news_url, DEFAULT_NEWS_URL);
    }
}
