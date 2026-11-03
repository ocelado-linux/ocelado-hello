//! Read-only information about the running system: Ocelado release,
//! edition, kernel, device model and session type.

use std::collections::HashMap;
use std::fs;
use std::path::Path;

/// Parsed `/etc/os-release` (or `/usr/lib/os-release`).
#[derive(Debug, Default, Clone)]
pub struct OsRelease {
    fields: HashMap<String, String>,
}

impl OsRelease {
    pub fn load() -> Self {
        for path in ["/etc/os-release", "/usr/lib/os-release"] {
            if let Ok(text) = fs::read_to_string(path) {
                return Self::parse(&text);
            }
        }
        Self::default()
    }

    pub fn parse(text: &str) -> Self {
        let mut fields = HashMap::new();
        for line in text.lines() {
            let line = line.trim();
            if line.is_empty() || line.starts_with('#') {
                continue;
            }
            if let Some((key, value)) = line.split_once('=') {
                let value = value.trim();
                let value = value
                    .strip_prefix('"')
                    .and_then(|v| v.strip_suffix('"'))
                    .or_else(|| value.strip_prefix('\'').and_then(|v| v.strip_suffix('\'')))
                    .unwrap_or(value);
                fields.insert(key.trim().to_string(), value.to_string());
            }
        }
        Self { fields }
    }

    pub fn get(&self, key: &str) -> Option<&str> {
        self.fields.get(key).map(String::as_str)
    }

    /// Ocelado release shown to the user ("0.3"). Falls back to VERSION_ID.
    pub fn version(&self) -> String {
        self.get("IMAGE_VERSION")
            .or_else(|| self.get("VERSION_ID"))
            .unwrap_or("")
            .to_string()
    }
}

/// Which Ocelado image is installed.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Edition {
    SteamDeck,
    Handheld,
    Desktop,
    DesktopMinimal,
}

impl Edition {
    /// Editions with the gamescope Game Mode session (and therefore Decky).
    pub fn has_game_mode(self) -> bool {
        matches!(self, Edition::SteamDeck | Edition::Handheld)
    }

    pub fn id(self) -> &'static str {
        match self {
            Edition::SteamDeck => "deck",
            Edition::Handheld => "handheld",
            Edition::Desktop => "desktop",
            Edition::DesktopMinimal => "desktop-minimal",
        }
    }

    pub fn display_name(self) -> &'static str {
        match self {
            Edition::SteamDeck => "Edición Steam Deck",
            Edition::Handheld => "Edición Handheld",
            Edition::Desktop => "Edición Desktop",
            Edition::DesktopMinimal => "Edición Desktop Minimal",
        }
    }

    /// Detects the edition from os-release `VARIANT_ID`, falling back to the
    /// device model when the variant is generic.
    pub fn detect(os: &OsRelease, device: &Device) -> Self {
        let variant = os.get("VARIANT_ID").unwrap_or("").to_ascii_lowercase();
        if variant.contains("minimal") {
            Edition::DesktopMinimal
        } else if variant.contains("desktop") {
            Edition::Desktop
        } else if variant.contains("deck") || device.is_steam_deck() {
            Edition::SteamDeck
        } else {
            Edition::Handheld
        }
    }
}

/// Hardware model from DMI.
#[derive(Debug, Default, Clone)]
pub struct Device {
    pub vendor: String,
    pub product: String,
}

impl Device {
    pub fn load() -> Self {
        let read = |name: &str| {
            fs::read_to_string(Path::new("/sys/class/dmi/id").join(name))
                .map(|s| s.trim().to_string())
                .unwrap_or_default()
        };
        Self {
            vendor: read("sys_vendor"),
            product: read("product_name"),
        }
    }

    /// Steam Deck LCD is "Jupiter", OLED is "Galileo".
    pub fn is_steam_deck(&self) -> bool {
        self.vendor.eq_ignore_ascii_case("valve")
            && matches!(self.product.as_str(), "Jupiter" | "Galileo")
    }

    pub fn display_name(&self) -> String {
        if self.is_steam_deck() {
            return match self.product.as_str() {
                "Galileo" => "Steam Deck OLED".into(),
                _ => "Steam Deck LCD".into(),
            };
        }
        let name = format!("{} {}", self.vendor, self.product);
        let name = name.trim();
        if name.is_empty() {
            "Desconocido".into()
        } else {
            name.to_string()
        }
    }
}

/// Which of the two shipped kernels is running.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum KernelFlavor {
    Ogc,
    Tkg,
    Other,
}

impl KernelFlavor {
    /// Guesses the flavor from `uname -r`. The exact suffixes depend on how
    /// kernel-ogc and linux-tkg are packaged; adjust here if they change.
    pub fn from_release(release: &str) -> Self {
        let r = release.to_ascii_lowercase();
        if r.contains("tkg") {
            KernelFlavor::Tkg
        } else if r.contains("ogc") {
            KernelFlavor::Ogc
        } else {
            KernelFlavor::Other
        }
    }

    pub fn id(self) -> &'static str {
        match self {
            KernelFlavor::Ogc => "ogc",
            KernelFlavor::Tkg => "tkg",
            KernelFlavor::Other => "other",
        }
    }
}

pub fn kernel_release() -> String {
    fs::read_to_string("/proc/sys/kernel/osrelease")
        .map(|s| s.trim().to_string())
        .unwrap_or_default()
}

/// True when running inside the gamescope Game Mode session.
pub fn in_game_mode() -> bool {
    std::env::var("XDG_CURRENT_DESKTOP")
        .map(|d| d.eq_ignore_ascii_case("gamescope"))
        .unwrap_or(false)
        || std::env::var_os("GAMESCOPE_WAYLAND_DISPLAY").is_some()
}

/// Highest x86-64 microarchitecture level the CPU supports (2, 3 or 4),
/// read from the flags in /proc/cpuinfo.
pub fn x86_64_level() -> Option<u8> {
    let info = fs::read_to_string("/proc/cpuinfo").ok()?;
    let flags_line = info.lines().find(|l| l.starts_with("flags"))?;
    let flags: Vec<&str> = flags_line.split_whitespace().collect();
    let has = |f: &str| flags.contains(&f);
    let v2 = ["cx16", "lahf_lm", "popcnt", "sse4_1", "sse4_2", "ssse3"]
        .iter()
        .all(|f| has(f));
    let v3 = v2
        && ["avx", "avx2", "bmi1", "bmi2", "f16c", "fma", "abm", "movbe", "xsave"]
            .iter()
            .all(|f| has(f));
    let v4 = v3 && ["avx512f", "avx512bw", "avx512cd", "avx512dq", "avx512vl"].iter().all(|f| has(f));
    Some(if v4 {
        4
    } else if v3 {
        3
    } else if v2 {
        2
    } else {
        1
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    const SAMPLE: &str = r#"
NAME="Ocelado Linux"
PRETTY_NAME="Ocelado Linux"
ID="opensuse-tumbleweed"
VERSION_ID="20261101"
IMAGE_VERSION="0.3"
VARIANT="Desktop"
VARIANT_ID="desktop"
LOGO="ocelado-logo"
"#;

    #[test]
    fn parses_os_release() {
        let os = OsRelease::parse(SAMPLE);
        assert_eq!(os.get("NAME"), Some("Ocelado Linux"));
        assert_eq!(os.version(), "0.3");
        assert_eq!(os.get("LOGO"), Some("ocelado-logo"));
    }

    #[test]
    fn detects_editions() {
        let deck = Device { vendor: "Valve".into(), product: "Jupiter".into() };
        let other = Device { vendor: "AOKZOE".into(), product: "AOKZOE A1X".into() };
        let os = OsRelease::parse(SAMPLE);
        assert_eq!(Edition::detect(&os, &deck), Edition::Desktop);
        let handheld = OsRelease::parse("VARIANT_ID=\"handheld\"");
        assert_eq!(Edition::detect(&handheld, &deck), Edition::SteamDeck);
        assert_eq!(Edition::detect(&handheld, &other), Edition::Handheld);
        let minimal = OsRelease::parse("VARIANT_ID=desktop-minimal");
        assert_eq!(Edition::detect(&minimal, &other), Edition::DesktopMinimal);
        assert!(!Edition::Desktop.has_game_mode());
        assert!(Edition::SteamDeck.has_game_mode());
    }

    #[test]
    fn device_names() {
        let oled = Device { vendor: "Valve".into(), product: "Galileo".into() };
        assert_eq!(oled.display_name(), "Steam Deck OLED");
        assert_eq!(Device::default().display_name(), "Desconocido");
    }

    #[test]
    fn kernel_flavors() {
        assert_eq!(KernelFlavor::from_release("6.17.2-1-ogc"), KernelFlavor::Ogc);
        assert_eq!(KernelFlavor::from_release("6.17.2-tkg-bore"), KernelFlavor::Tkg);
        assert_eq!(KernelFlavor::from_release("6.17.2-1-default"), KernelFlavor::Other);
    }
}
