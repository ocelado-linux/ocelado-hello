//! Disks: what is plugged in, how full it is, whether Steam uses it, and
//! preparing a microSD/USB disk for games.

use serde::Serialize;
use serde_json::Value;
use std::fs;
use std::process::{Command, Stdio};

use crate::config::home_dir;
use crate::privileged::{self, HELPER};

/// Mount points that mark a disk as the system disk.
const SYSTEM_MOUNTS: &[&str] = &["/", "/var", "/home", "/boot", "/boot/efi", "/usr", "/etc", "/.snapshots"];

#[derive(Debug, Clone, Serialize, PartialEq)]
pub struct Disk {
    /// /dev path of the whole disk.
    pub path: String,
    pub name: String,
    pub model: String,
    pub size: u64,
    /// "nvme", "usb", "mmc"…
    pub transport: String,
    pub system: bool,
    pub removable: bool,
    /// Mounted filesystems on this disk (partitions or the disk itself).
    pub mounts: Vec<Mount>,
    /// Filesystem types found, even if not mounted ("ext4", "exfat"…).
    pub fstypes: Vec<String>,
    pub steam_library: bool,
}

#[derive(Debug, Clone, Serialize, PartialEq)]
pub struct Mount {
    pub device: String,
    pub mountpoint: String,
    pub fstype: String,
    pub used: u64,
    pub size: u64,
}

fn as_u64(v: Option<&Value>) -> u64 {
    match v {
        Some(Value::Number(n)) => n.as_u64().unwrap_or(0),
        Some(Value::String(s)) => s.parse().unwrap_or(0),
        _ => 0,
    }
}

fn as_bool(v: Option<&Value>) -> bool {
    match v {
        Some(Value::Bool(b)) => *b,
        Some(Value::String(s)) => s == "1" || s == "true",
        Some(Value::Number(n)) => n.as_u64() == Some(1),
        _ => false,
    }
}

fn as_str(v: Option<&Value>) -> String {
    v.and_then(Value::as_str).unwrap_or("").trim().to_string()
}

fn mountpoints(dev: &Value) -> Vec<String> {
    if let Some(list) = dev.get("mountpoints").and_then(Value::as_array) {
        list.iter().filter_map(Value::as_str).map(str::to_string).collect()
    } else {
        dev.get("mountpoint").and_then(Value::as_str).map(|m| vec![m.to_string()]).unwrap_or_default()
    }
}

/// Walks a disk and its children collecting mounts and filesystem types.
fn collect(dev: &Value, mounts: &mut Vec<Mount>, fstypes: &mut Vec<String>) {
    let fstype = as_str(dev.get("fstype"));
    if !fstype.is_empty() && !fstypes.contains(&fstype) {
        fstypes.push(fstype.clone());
    }
    for mp in mountpoints(dev) {
        if mp.starts_with('[') {
            continue; // [SWAP]
        }
        mounts.push(Mount {
            device: as_str(dev.get("path")),
            mountpoint: mp,
            fstype: fstype.clone(),
            used: as_u64(dev.get("fsused")),
            size: as_u64(dev.get("fssize")),
        });
    }
    for child in dev.get("children").and_then(Value::as_array).into_iter().flatten() {
        collect(child, mounts, fstypes);
    }
}

/// Parses `lsblk -J -b -o …` (see [`LSBLK_COLUMNS`]).
pub fn parse_lsblk(json: &str, libraries: &[String]) -> Vec<Disk> {
    let Ok(v) = serde_json::from_str::<Value>(json) else {
        return Vec::new();
    };
    v.get("blockdevices")
        .and_then(Value::as_array)
        .into_iter()
        .flatten()
        .filter(|d| as_str(d.get("type")) == "disk")
        .filter(|d| as_u64(d.get("size")) > 0)
        .filter(|d| {
            let name = as_str(d.get("name"));
            !(name.starts_with("zram") || name.starts_with("loop") || name.starts_with("sr"))
        })
        .map(|d| {
            let mut mounts = Vec::new();
            let mut fstypes = Vec::new();
            collect(d, &mut mounts, &mut fstypes);
            // Btrfs subvolumes show the same device several times: keep each
            // device once, preferring its shortest mount point.
            mounts.sort_by(|a, b| a.device.cmp(&b.device).then(a.mountpoint.len().cmp(&b.mountpoint.len())));
            let system = mounts.iter().any(|m| SYSTEM_MOUNTS.contains(&m.mountpoint.as_str()));
            mounts.dedup_by(|a, b| a.device == b.device);
            let name = as_str(d.get("name"));
            let transport = as_str(d.get("tran"));
            let removable = !system
                && (as_bool(d.get("rm"))
                    || as_bool(d.get("hotplug"))
                    || name.starts_with("mmcblk")
                    || transport == "usb"
                    || transport == "mmc");
            let steam_library = mounts.iter().any(|m| {
                m.mountpoint != "/"
                    && libraries.iter().any(|l| l == &m.mountpoint || l.starts_with(&format!("{}/", m.mountpoint)))
            });
            Disk {
                path: as_str(d.get("path")),
                model: as_str(d.get("model")),
                size: as_u64(d.get("size")),
                name,
                transport,
                system,
                removable,
                mounts,
                fstypes,
                steam_library,
            }
        })
        .collect()
}

pub const LSBLK_COLUMNS: &str = "NAME,PATH,TYPE,SIZE,RM,HOTPLUG,TRAN,MODEL,FSTYPE,MOUNTPOINTS,FSUSED,FSSIZE";

/// Steam library paths from libraryfolders.vdf (only the `"path"` keys).
pub fn steam_libraries() -> Vec<String> {
    let home = home_dir();
    let candidates = [
        home.join(".local/share/Steam/steamapps/libraryfolders.vdf"),
        home.join(".steam/steam/steamapps/libraryfolders.vdf"),
    ];
    let Some(text) = candidates.iter().find_map(|p| fs::read_to_string(p).ok()) else {
        return Vec::new();
    };
    parse_library_paths(&text)
}

pub fn parse_library_paths(vdf: &str) -> Vec<String> {
    vdf.lines()
        .filter_map(|l| {
            let l = l.trim();
            let rest = l.strip_prefix("\"path\"")?.trim();
            Some(rest.trim_matches('"').replace("\\\\", "\\"))
        })
        .collect()
}

pub fn disks() -> Vec<Disk> {
    let out = Command::new("lsblk")
        .args(["-J", "-b", "-o", LSBLK_COLUMNS])
        .stdin(Stdio::null())
        .output();
    match out {
        Ok(o) if o.status.success() => parse_lsblk(&String::from_utf8_lossy(&o.stdout), &steam_libraries()),
        _ => Vec::new(),
    }
}

/// Wipes the disk and creates one ext4 partition owned by the user, then
/// mounts it through udisks. Returns the mount point.
pub fn format_for_games(disk: &str) -> Result<String, String> {
    let target = disks()
        .into_iter()
        .find(|d| d.path == disk)
        .ok_or_else(|| format!("No se encuentra el disco {disk}"))?;
    if target.system || !target.removable {
        return Err("Solo se pueden formatear tarjetas microSD y discos externos.".into());
    }
    let out = privileged::run(HELPER, &["format-device", disk])?;
    // The helper prints the new partition, e.g. /dev/mmcblk0p1
    let part = out.lines().rev().find(|l| l.starts_with("/dev/")).unwrap_or("").trim().to_string();
    if part.is_empty() {
        return Ok(String::new());
    }
    let mounted = privileged::output_of("udisksctl", &["mount", "--no-user-interaction", "-b", &part]).unwrap_or_default();
    // "Mounted /dev/mmcblk0p1 at /run/media/user/Juegos"
    Ok(mounted.split(" at ").nth(1).unwrap_or("").trim().trim_end_matches('.').to_string())
}

pub fn eject(disk: &str) -> Result<(), String> {
    let target = disks().into_iter().find(|d| d.path == disk).ok_or("Disco no encontrado")?;
    for m in &target.mounts {
        privileged::output_of("udisksctl", &["unmount", "-b", &m.device])
            .ok_or_else(|| format!("No se pudo desmontar {}", m.mountpoint))?;
    }
    privileged::output_of("udisksctl", &["power-off", "-b", disk]);
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    const LSBLK: &str = r#"{"blockdevices":[
      {"name":"nvme0n1","path":"/dev/nvme0n1","type":"disk","size":512110190592,"rm":false,"hotplug":false,"tran":"nvme","model":"WD SN740","fstype":null,"mountpoints":[null],"fsused":null,"fssize":null,
       "children":[
         {"name":"nvme0n1p1","path":"/dev/nvme0n1p1","type":"part","size":536870912,"rm":false,"hotplug":false,"tran":"nvme","model":null,"fstype":"vfat","mountpoints":["/boot/efi"],"fsused":"6000000","fssize":"536000000"},
         {"name":"nvme0n1p2","path":"/dev/nvme0n1p2","type":"part","size":511000000000,"rm":false,"hotplug":false,"tran":"nvme","model":null,"fstype":"btrfs","mountpoints":["/var","/","/home"],"fsused":"100000000000","fssize":"511000000000"}]},
      {"name":"mmcblk0","path":"/dev/mmcblk0","type":"disk","size":256000000000,"rm":false,"hotplug":true,"tran":null,"model":null,"fstype":null,"mountpoints":[null],"fsused":null,"fssize":null,
       "children":[{"name":"mmcblk0p1","path":"/dev/mmcblk0p1","type":"part","size":255000000000,"rm":false,"hotplug":true,"tran":null,"model":null,"fstype":"ext4","mountpoints":["/run/media/gamer/Juegos"],"fsused":"1000","fssize":"250000000000"}]},
      {"name":"zram0","path":"/dev/zram0","type":"disk","size":8000000000,"rm":false,"hotplug":false,"tran":null,"model":null,"fstype":"swap","mountpoints":["[SWAP]"],"fsused":null,"fssize":null}
    ]}"#;

    #[test]
    fn parses_disks() {
        let libs = vec!["/run/media/gamer/Juegos".to_string()];
        let d = parse_lsblk(LSBLK, &libs);
        assert_eq!(d.len(), 2);
        assert!(d[0].system && !d[0].removable);
        assert_eq!(d[0].mounts.iter().filter(|m| m.device == "/dev/nvme0n1p2").count(), 1);
        assert_eq!(d[0].mounts.iter().find(|m| m.device == "/dev/nvme0n1p2").unwrap().mountpoint, "/");
        assert!(!d[0].steam_library);
        assert!(d[1].removable && d[1].steam_library);
        assert_eq!(d[1].mounts[0].size, 250000000000);
    }

    #[test]
    fn parses_library_vdf() {
        let vdf = "\"libraryfolders\"\n{\n\t\"0\"\n\t{\n\t\t\"path\"\t\t\"/home/gamer/.local/share/Steam\"\n\t}\n\t\"1\"\n\t{\n\t\t\"path\"\t\t\"/run/media/gamer/Juegos\"\n\t}\n}";
        assert_eq!(parse_library_paths(vdf), vec!["/home/gamer/.local/share/Steam", "/run/media/gamer/Juegos"]);
    }
}
