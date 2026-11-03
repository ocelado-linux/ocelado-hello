//! Fan speed and temperatures from hwmon, for the Controllers & hardware page.

use serde::Serialize;
use std::fs;
use std::path::Path;

#[derive(Debug, Clone, Serialize, Default, PartialEq)]
pub struct Sensors {
    /// Fan speeds in RPM (one per fan found).
    pub fans: Vec<u32>,
    /// CPU/APU temperature in °C, if found.
    pub cpu_temp: Option<f32>,
    /// GPU temperature in °C, if found (separate GPU or amdgpu edge).
    pub gpu_temp: Option<f32>,
}

fn read_num(path: &Path) -> Option<i64> {
    fs::read_to_string(path).ok()?.trim().parse().ok()
}

pub fn read() -> Sensors {
    read_from(Path::new("/sys/class/hwmon"))
}

pub fn read_from(root: &Path) -> Sensors {
    let mut s = Sensors::default();
    let Ok(entries) = fs::read_dir(root) else {
        return s;
    };
    let mut dirs: Vec<_> = entries.flatten().map(|e| e.path()).collect();
    dirs.sort();
    for dir in dirs {
        let name = fs::read_to_string(dir.join("name")).unwrap_or_default();
        let name = name.trim();
        for i in 1..=4 {
            if let Some(rpm) = read_num(&dir.join(format!("fan{i}_input"))) {
                if rpm >= 0 {
                    s.fans.push(rpm as u32);
                }
            }
        }
        let temp1 = read_num(&dir.join("temp1_input")).map(|m| m as f32 / 1000.0);
        match name {
            "k10temp" | "coretemp" | "zenpower" if s.cpu_temp.is_none() => s.cpu_temp = temp1,
            "amdgpu" | "nvidia" | "nouveau" if s.gpu_temp.is_none() => s.gpu_temp = temp1,
            _ => {}
        }
    }
    s
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn reads_fake_hwmon() {
        let root = std::env::temp_dir().join(format!("ocelado-hwmon-{}", std::process::id()));
        let _ = fs::remove_dir_all(&root);
        let h0 = root.join("hwmon0");
        let h1 = root.join("hwmon1");
        fs::create_dir_all(&h0).unwrap();
        fs::create_dir_all(&h1).unwrap();
        fs::write(h0.join("name"), "k10temp\n").unwrap();
        fs::write(h0.join("temp1_input"), "52500\n").unwrap();
        fs::write(h1.join("name"), "steamdeck_hwmon\n").unwrap();
        fs::write(h1.join("fan1_input"), "2900\n").unwrap();
        let s = read_from(&root);
        assert_eq!(s.fans, vec![2900]);
        assert_eq!(s.cpu_temp, Some(52.5));
        assert_eq!(s.gpu_temp, None);
        let _ = fs::remove_dir_all(&root);
    }
}
