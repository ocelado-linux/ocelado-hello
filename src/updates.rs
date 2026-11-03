//! System updates (transactional-update) and btrfs snapshots (snapper).

use serde::Serialize;
use serde_json::Value;
use std::process::{Command, Stdio};

use crate::privileged::{self, HELPER, QUERY};

/// A snapper snapshot as shown to the user.
#[derive(Debug, Clone, Serialize, PartialEq)]
pub struct Snapshot {
    pub number: u64,
    pub date: String,
    pub description: String,
    /// Currently running.
    pub active: bool,
    /// Will be used at the next boot.
    pub default: bool,
}

/// Parses `snapper --jsonout list`. Unknown or missing fields are tolerated,
/// snapshot 0 ("current") is skipped and the newest come first.
pub fn parse_snapshots(json: &str) -> Vec<Snapshot> {
    let Ok(value) = serde_json::from_str::<Value>(json) else {
        return Vec::new();
    };
    let list = value
        .get("root")
        .and_then(Value::as_array)
        .or_else(|| value.as_object().and_then(|o| o.values().find_map(Value::as_array)));
    let mut snaps: Vec<Snapshot> = list
        .into_iter()
        .flatten()
        .filter_map(|s| {
            let number = s.get("number")?.as_u64()?;
            if number == 0 {
                return None;
            }
            let text = |k: &str| s.get(k).and_then(Value::as_str).unwrap_or("").to_string();
            let flag = |k: &str| s.get(k).and_then(Value::as_bool).unwrap_or(false);
            Some(Snapshot {
                number,
                date: text("date"),
                description: text("description"),
                active: flag("active"),
                default: flag("default"),
            })
        })
        .collect();
    snaps.sort_by(|a, b| b.number.cmp(&a.number));
    snaps
}

/// Lists snapshots through the read-only helper.
pub fn list_snapshots() -> Result<Vec<Snapshot>, String> {
    privileged::run(QUERY, &["snapshots"]).map(|out| parse_snapshots(&out))
}

/// True when the next boot will use a different snapshot than the running
/// one (an update or a rollback is waiting for a reboot).
pub fn reboot_pending(snaps: &[Snapshot]) -> bool {
    let active = snaps.iter().find(|s| s.active).map(|s| s.number);
    let default = snaps.iter().find(|s| s.default).map(|s| s.number);
    matches!((active, default), (Some(a), Some(d)) if a != d)
}

/// `dup` into a new snapshot. Blocking; can take several minutes.
pub fn update_system() -> Result<(), String> {
    privileged::run(HELPER, &["update"]).map(|_| ())
}

/// Updates Flatpak apps (system and user). Blocking.
pub fn update_flatpaks() -> Result<(), String> {
    let status = Command::new("flatpak")
        .args(["update", "-y", "--noninteractive"])
        .stdin(Stdio::null())
        .status()
        .map_err(|e| format!("No se pudo ejecutar flatpak: {e}"))?;
    if status.success() {
        Ok(())
    } else {
        Err(format!("flatpak terminó con error ({status})"))
    }
}

pub fn rollback(number: u64) -> Result<(), String> {
    privileged::run(HELPER, &["rollback", &number.to_string()]).map(|_| ())
}

/// Whether transactional-update.timer (background updates) is enabled.
pub fn auto_updates_enabled() -> bool {
    privileged::output_of("systemctl", &["is-enabled", "transactional-update.timer"])
        .is_some_and(|s| s.trim() == "enabled")
}

pub fn set_auto_updates(on: bool) -> Result<(), String> {
    privileged::run(HELPER, &["auto-updates", if on { "on" } else { "off" }]).map(|_| ())
}

pub fn reboot() -> Result<(), String> {
    Command::new("systemctl")
        .arg("reboot")
        .spawn()
        .map(|_| ())
        .map_err(|e| format!("No se pudo reiniciar: {e}"))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_snapper_json() {
        let json = r#"{"root":[
            {"number":0,"default":false,"active":false,"date":"","description":"current"},
            {"number":20,"default":false,"active":true,"date":"2026-11-01 10:00:00","description":"Snapshot Update of #19","userdata":null},
            {"number":22,"default":true,"active":false,"date":"2026-11-02 09:00:00","description":"Snapshot Update of #20"}
        ]}"#;
        let s = parse_snapshots(json);
        assert_eq!(s.len(), 2);
        assert_eq!(s[0].number, 22);
        assert!(s[0].default);
        assert!(s[1].active);
        assert!(reboot_pending(&s));
        assert!(parse_snapshots("not json").is_empty());
    }
}
