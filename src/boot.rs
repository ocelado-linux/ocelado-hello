//! Boot options: which session starts at power-on (Game Mode editions) and
//! which kernels are installed.

use serde::Serialize;
use std::fs;

use crate::privileged::{self, HELPER};
use crate::system::KernelFlavor;

/// Read by deckifier's steamos-startup-gamescope at boot:
/// `BOOT_SESSION=last|gamemode|desktop`.
pub const BOOT_SESSION_FILES: &[&str] =
    &["/etc/ocelado/boot-session.conf", "/etc/ogc-handheld/boot-session.conf"];

pub fn boot_session() -> String {
    for path in BOOT_SESSION_FILES {
        if let Ok(text) = fs::read_to_string(path) {
            return parse_boot_session(&text);
        }
    }
    "last".into()
}

pub fn parse_boot_session(text: &str) -> String {
    let value = text
        .lines()
        .filter_map(|l| l.trim().strip_prefix("BOOT_SESSION="))
        .last()
        .unwrap_or("last")
        .trim()
        .trim_matches('"');
    match value {
        "gamemode" | "gamescope" => "gamemode",
        "desktop" | "plasma" => "desktop",
        _ => "last",
    }
    .into()
}

pub fn set_boot_session(mode: &str) -> Result<(), String> {
    if !matches!(mode, "last" | "gamemode" | "desktop") {
        return Err(format!("Modo de arranque no válido: {mode}"));
    }
    privileged::run(HELPER, &["boot-session", mode]).map(|_| ())
}

#[derive(Debug, Clone, Serialize, PartialEq)]
pub struct InstalledKernel {
    pub flavor: &'static str,
    pub release: String,
}

/// Kernels found in /boot (`vmlinuz-<release>`), with their flavor.
pub fn installed_kernels() -> Vec<InstalledKernel> {
    let mut list: Vec<InstalledKernel> = fs::read_dir("/boot")
        .into_iter()
        .flatten()
        .flatten()
        .filter_map(|e| {
            let name = e.file_name().to_string_lossy().into_owned();
            let release = name.strip_prefix("vmlinuz-")?.to_string();
            Some(InstalledKernel { flavor: KernelFlavor::from_release(&release).id(), release })
        })
        .collect();
    list.sort_by(|a, b| a.release.cmp(&b.release));
    list
}

/// Sets the GRUB entry of the newest kernel of that flavor for the next boot
/// only (grub2-reboot), then reboots.
pub fn reboot_into(flavor: &str) -> Result<(), String> {
    if !matches!(flavor, "ogc" | "tkg") {
        return Err(format!("Kernel no válido: {flavor}"));
    }
    privileged::run(HELPER, &["next-kernel", flavor])?;
    crate::updates::reboot()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn boot_session_values() {
        assert_eq!(parse_boot_session("BOOT_SESSION=gamemode\n"), "gamemode");
        assert_eq!(parse_boot_session("# c\nBOOT_SESSION=\"desktop\""), "desktop");
        assert_eq!(parse_boot_session("BOOT_SESSION=last"), "last");
        assert_eq!(parse_boot_session(""), "last");
        assert_eq!(parse_boot_session("BOOT_SESSION=evil"), "last");
    }
}
