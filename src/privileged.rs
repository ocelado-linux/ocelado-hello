//! Runs the root helpers through pkexec. Each helper only accepts a fixed
//! set of subcommands (see `data/ocelado-hello-helper` and
//! `data/ocelado-hello-query`); polkit decides whether a password is asked.

use std::path::PathBuf;
use std::process::{Command, Stdio};

/// Actions that change the system (asks for the admin password once).
pub const HELPER: &str = "ocelado-hello-helper";
/// Read-only queries (no password for the active local session).
pub const QUERY: &str = "ocelado-hello-query";

/// Directory with the helpers. `OCELADO_HELLO_LIBEXEC` overrides it for
/// development; pkexec still needs a matching polkit policy to run them.
pub fn helper_path(name: &str) -> PathBuf {
    let dir = std::env::var_os("OCELADO_HELLO_LIBEXEC")
        .map(PathBuf::from)
        .unwrap_or_else(|| PathBuf::from("/usr/libexec/ocelado-hello"));
    dir.join(name)
}

/// Runs `pkexec <helper> <args…>` and returns its standard output.
pub fn run(helper: &str, args: &[&str]) -> Result<String, String> {
    let output = Command::new("pkexec")
        .arg(helper_path(helper))
        .args(args)
        .stdin(Stdio::null())
        .output()
        .map_err(|e| format!("No se pudo ejecutar pkexec: {e}"))?;
    if output.status.success() {
        return Ok(String::from_utf8_lossy(&output.stdout).into_owned());
    }
    // pkexec: 126 = dialog dismissed, 127 = not authorized
    match output.status.code() {
        Some(126) => Err("Autorización cancelada.".into()),
        Some(127) => Err("No tienes permiso para hacer esto.".into()),
        _ => {
            let stderr = String::from_utf8_lossy(&output.stderr);
            let last = stderr.lines().rev().find(|l| !l.trim().is_empty()).unwrap_or("").trim();
            if last.is_empty() {
                Err(format!("La operación falló ({})", output.status))
            } else {
                Err(last.to_string())
            }
        }
    }
}

/// Runs a normal (unprivileged) command and returns stdout if it succeeded.
pub fn output_of(cmd: &str, args: &[&str]) -> Option<String> {
    Command::new(cmd)
        .args(args)
        .stdin(Stdio::null())
        .stderr(Stdio::null())
        .output()
        .ok()
        .filter(|o| o.status.success())
        .map(|o| String::from_utf8_lossy(&o.stdout).into_owned())
}
