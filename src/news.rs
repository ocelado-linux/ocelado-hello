//! "Novedades": release notes for the user, read from a JSON file published
//! on the Ocelado website so they can change without a new build.
//!
//! Format (see `data/novedades.example.json`):
//! ```json
//! { "releases": [
//!     { "version": "0.4", "title": "Novedades en Ocelado 0.4",
//!       "url": "https://…", "items": [ { "title": "…", "text": "…" } ] } ] }
//! ```

use serde::{Deserialize, Serialize};
use std::time::Duration;

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct NewsItem {
    pub title: String,
    #[serde(default)]
    pub text: String,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct Release {
    pub version: String,
    #[serde(default)]
    pub title: String,
    #[serde(default)]
    pub url: String,
    #[serde(default)]
    pub items: Vec<NewsItem>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct NewsFile {
    #[serde(default)]
    pub releases: Vec<Release>,
}

impl NewsFile {
    pub fn parse(json: &str) -> Result<Self, serde_json::Error> {
        serde_json::from_str(json)
    }

    /// News for exactly this Ocelado version, if published and not empty.
    pub fn for_version(&self, version: &str) -> Option<&Release> {
        self.releases
            .iter()
            .find(|r| r.version == version && !r.items.is_empty())
    }
}

/// Downloads the news file. Short timeout: at login the network may not be
/// up yet, in which case we simply try again next time.
pub fn fetch(url: &str) -> Result<NewsFile, String> {
    let agent: ureq::Agent = ureq::Agent::config_builder()
        .timeout_global(Some(Duration::from_secs(10)))
        .build()
        .into();
    let body = agent
        .get(url)
        .header("User-Agent", concat!("ocelado-hello/", env!("CARGO_PKG_VERSION")))
        .call()
        .map_err(|e| e.to_string())?
        .body_mut()
        .read_to_string()
        .map_err(|e| e.to_string())?;
    NewsFile::parse(&body).map_err(|e| e.to_string())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn example_file_parses() {
        let text = include_str!("../data/novedades.example.json");
        let news = NewsFile::parse(text).unwrap();
        let r = news.for_version("0.4").expect("0.4 news");
        assert!(!r.items.is_empty());
        assert!(news.for_version("9.9").is_none());
    }
}
