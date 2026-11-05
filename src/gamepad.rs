//! Gamepad input (Qt 6 has no gamepad module). A background thread reads
//! controllers with gilrs and reports two kinds of events:
//! - navigation actions: "up", "down", "left", "right", "accept", "back",
//!   "x", "y", "prev", "next";
//! - raw button presses and releases by name for the button test ("A",
//!   "B", "L1"…); the release lets the test detect B held down.

pub enum Event {
    Nav(&'static str),
    Button(&'static str),
    Release(&'static str),
}

#[cfg(feature = "gamepad")]
fn button_name(button: gilrs::Button) -> &'static str {
    use gilrs::Button::*;
    match button {
        South => "A",
        East => "B",
        West => "X",
        North => "Y",
        LeftTrigger => "L1",
        RightTrigger => "R1",
        LeftTrigger2 => "L2",
        RightTrigger2 => "R2",
        Select => "View",
        Start => "Menu",
        Mode => "Guía",
        LeftThumb => "L3",
        RightThumb => "R3",
        DPadUp => "Arriba",
        DPadDown => "Abajo",
        DPadLeft => "Izquierda",
        DPadRight => "Derecha",
        C => "C",
        Z => "Z",
        _ => "Otro",
    }
}

#[cfg(feature = "gamepad")]
pub fn spawn(send: impl Fn(Event) + Send + 'static) {
    use gilrs::{Axis, Button, EventType, GamepadId, Gilrs};
    use std::time::{Duration, Instant};

    // The same physical controller can show up twice (the Deck's own
    // device and Steam's virtual one): ignore a press repeated by another
    // device right after.
    let mut last: Option<(&'static str, Instant, GamepadId)> = None;
    let mut fresh = move |what: &'static str, id: GamepadId| -> bool {
        let now = Instant::now();
        let dup = matches!(last, Some((w, t, i)) if w == what && i != id && now.duration_since(t) < Duration::from_millis(150));
        if !dup {
            last = Some((what, now, id));
        }
        !dup
    };

    std::thread::spawn(move || {
        let mut gilrs = match Gilrs::new() {
            Ok(g) => g,
            Err(e) => {
                eprintln!("ocelado-hello: sin mandos ({e})");
                return;
            }
        };
        // Left stick acts like the d-pad, with a simple repeat delay.
        let mut last_stick = Instant::now() - Duration::from_secs(1);
        let mut stick_neutral = true;
        loop {
            while let Some(ev) = gilrs.next_event_blocking(Some(Duration::from_millis(200))) {
                match ev.event {
                    EventType::ButtonPressed(button, _) => {
                        if !fresh(button_name(button), ev.id) {
                            continue;
                        }
                        send(Event::Button(button_name(button)));
                        let action = match button {
                            Button::DPadUp => "up",
                            Button::DPadDown => "down",
                            Button::DPadLeft => "left",
                            Button::DPadRight => "right",
                            Button::South => "accept",
                            Button::East => "back",
                            Button::West => "x",
                            Button::North => "y",
                            Button::LeftTrigger => "prev",
                            Button::RightTrigger => "next",
                            _ => continue,
                        };
                        send(Event::Nav(action));
                    }
                    EventType::ButtonReleased(button, _) => {
                        send(Event::Release(button_name(button)));
                    }
                    EventType::AxisChanged(axis @ (Axis::LeftStickX | Axis::LeftStickY), value, _) => {
                        if value.abs() < 0.3 {
                            stick_neutral = true;
                            continue;
                        }
                        if value.abs() < 0.7 {
                            continue;
                        }
                        let repeat = Duration::from_millis(if stick_neutral { 0 } else { 250 });
                        if last_stick.elapsed() < repeat {
                            continue;
                        }
                        stick_neutral = false;
                        last_stick = Instant::now();
                        let action = match (axis, value > 0.0) {
                            (Axis::LeftStickX, true) => "right",
                            (Axis::LeftStickX, false) => "left",
                            // gilrs: positive Y is up
                            (_, true) => "up",
                            (_, false) => "down",
                        };
                        if !fresh(action, ev.id) {
                            continue;
                        }
                        send(Event::Nav(action));
                    }
                    _ => {}
                }
            }
        }
    });
}

#[cfg(not(feature = "gamepad"))]
pub fn spawn(_send: impl Fn(Event) + Send + 'static) {}
