//! Gamepad input (Qt 6 has no gamepad module). A background thread reads
//! controllers with gilrs and reports two kinds of events:
//! - navigation actions: "up", "down", "left", "right", "accept", "back",
//!   "x", "y", "prev", "next";
//! - raw button names for the button test ("A", "B", "L1", "R4"…).

pub enum Event {
    Nav(&'static str),
    Button(&'static str),
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
    use gilrs::{Axis, Button, EventType, Gilrs};
    use std::time::{Duration, Instant};

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
