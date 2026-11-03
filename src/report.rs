//! Bug report: collects system info (and optionally logs), saves it to the
//! Downloads folder and builds a GitHub "new issue" URL plus a QR code for it,
//! so a handheld user can continue on their phone.

use qrcode::{EcLevel, QrCode, render::svg};
use std::fs;
use std::path::PathBuf;
use std::process::Command;

use crate::config::home_dir;

/// Where bug reports are filed.
pub const ISSUES_URL: &str = "https://github.com/ocelado-linux/ocelado-hello/issues/new";

pub struct SystemSummary {
    pub lines: Vec<(String, String)>,
}

impl SystemSummary {
    pub fn to_text(&self) -> String {
        self.lines
            .iter()
            .map(|(k, v)| format!("{k}: {v}"))
            .collect::<Vec<_>>()
            .join("\n")
    }
}

pub struct Report {
    pub path: PathBuf,
    pub issue_url: String,
    pub qr_svg: String,
}

fn command_output(cmd: &str, args: &[&str]) -> String {
    Command::new(cmd)
        .args(args)
        .output()
        .ok()
        .filter(|o| o.status.success())
        .map(|o| String::from_utf8_lossy(&o.stdout).into_owned())
        .unwrap_or_default()
}

pub fn downloads_dir() -> PathBuf {
    let dir = command_output("xdg-user-dir", &["DOWNLOAD"]);
    let dir = dir.trim();
    if !dir.is_empty() {
        PathBuf::from(dir)
    } else {
        home_dir().join("Downloads")
    }
}

/// Replaces the user name and host name so logs can be shared.
pub fn redact(text: &str) -> String {
    let mut out = text.to_string();
    let host = fs::read_to_string("/etc/hostname").unwrap_or_default();
    let host = host.trim();
    if host.len() > 2 {
        out = out.replace(host, "<equipo>");
    }
    if let Some(user) = std::env::var("USER").ok().filter(|u| u.len() > 2) {
        out = out.replace(&user, "<usuario>");
    }
    out
}

pub fn percent_encode(s: &str) -> String {
    let mut out = String::with_capacity(s.len() * 3);
    for b in s.bytes() {
        match b {
            b'A'..=b'Z' | b'a'..=b'z' | b'0'..=b'9' | b'-' | b'_' | b'.' | b'~' => out.push(b as char),
            _ => out.push_str(&format!("%{b:02X}")),
        }
    }
    out
}

pub fn issue_url(description: &str, summary: &SystemSummary) -> String {
    let title = description.lines().next().unwrap_or("").trim();
    let title = if title.is_empty() { "Informe de fallo" } else { title };
    let title: String = title.chars().take(80).collect();
    let body = format!(
        "### Qué ha pasado\n\n{}\n\n### Sistema\n\n```\n{}\n```\n\n_Los registros completos están en el archivo guardado por ocelado-hello; adjúntalo si te lo piden._\n",
        if description.trim().is_empty() { "(describe el fallo aquí)" } else { description.trim() },
        summary.to_text()
    );
    format!("{ISSUES_URL}?title={}&body={}", percent_encode(&title), percent_encode(&body))
}

pub fn qr_svg(data: &str) -> Result<String, String> {
    let code = QrCode::with_error_correction_level(data.as_bytes(), EcLevel::L)
        .map_err(|e| e.to_string())?;
    Ok(code
        .render::<svg::Color>()
        .min_dimensions(240, 240)
        .quiet_zone(true)
        .build())
}

pub fn create(
    description: &str,
    summary: &SystemSummary,
    include_journal: bool,
    include_decky: bool,
) -> Result<Report, String> {
    let mut text = format!(
        "Informe de ocelado-hello\n========================\n\n{}\n\nDescripción:\n{}\n",
        summary.to_text(),
        description.trim()
    );
    if include_journal {
        text.push_str("\n--- journalctl -b (últimas 3000 líneas) ---\n");
        text.push_str(&command_output("journalctl", &["-b", "--no-pager", "-n", "3000"]));
    }
    if include_decky {
        text.push_str("\n--- journalctl -u plugin_loader (últimas 500 líneas) ---\n");
        text.push_str(&command_output(
            "journalctl",
            &["-b", "--no-pager", "-n", "500", "-u", "plugin_loader.service"],
        ));
    }
    let text = redact(&text);

    let dir = downloads_dir();
    fs::create_dir_all(&dir).map_err(|e| e.to_string())?;
    let stamp = command_output("date", &["+%Y%m%d-%H%M%S"]);
    let stamp = stamp.trim();
    let path = dir.join(format!("ocelado-informe-{}.txt", if stamp.is_empty() { "0" } else { stamp }));
    fs::write(&path, text).map_err(|e| e.to_string())?;

    let url = issue_url(description, summary);
    let qr = qr_svg(&url)?;
    Ok(Report { path, issue_url: url, qr_svg: qr })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn encodes() {
        assert_eq!(percent_encode("a b/ñ"), "a%20b%2F%C3%B1");
    }

    #[test]
    fn builds_issue_url_and_qr() {
        let s = SystemSummary { lines: vec![("Kernel".into(), "6.17-ogc".into())] };
        let url = issue_url("La pantalla se queda en negro\nal volver", &s);
        assert!(url.starts_with(ISSUES_URL));
        assert!(url.contains("title=La%20pantalla"));
        let svg = qr_svg(&url).unwrap();
        assert!(svg.contains("<svg"));
    }
}
