# Retro Engineering HUD

The HUD broadcasts its selected theme and opacity settings to compatible CSP Lua apps once per second, allowing companion instruments to stay visually synchronized.

A compact retro motorsport HUD for Assetto Corsa, built as a native Custom Shaders Patch Lua app.

![Retro Engineering HUD in Assetto Corsa](assets/retro-engineering-hud.png)

## Features

- Digital, analog and panoramic GT7 Retro instrument modes.
- Central speed/gear readout, RPM arc, redline and shift alerts.
- Digital race-flag alerts and GT7 Retro dial bezels that share the active flag color and blink.
- Embedded, blinking bezel indicators.
- Brake/throttle bars, TC, ABS, lights, pit status and clutch display.
- Optional turbo or fuel lower gauge in analog mode.
- Primitive-drawn panoramic cluster with independently selectable digital bars or inertial speed/RPM needles, inertial boost, fuel and a live analog FFB magnitude meter.
- Light and dark dial themes.
- Persistent visual, RPM and display settings.

## Requirements

- Assetto Corsa (PC).
- Custom Shaders Patch with Lua apps enabled.
- Content Manager is recommended.

## Install

1. Download `RetroEngineeringHUD-v1.0.3.zip` from [Releases](../../releases).
2. Drag the ZIP into Content Manager and accept the install prompt.
3. Enable **Retro Engineering HUD** in the in-game Lua app sidebar.

For a manual install, extract the archive into the Assetto Corsa root. It contains `apps/lua/RetroEngineeringHUD/`.

Use the app settings window to cycle through the three layouts, choose the light or dark theme, set the RPM thresholds, and tune scale and transparency. GT7 Retro preserves a wide aspect ratio inside the existing app window; widen the window for its largest presentation.

The GT7 Retro FFB gauge reads CSP's `ac.getCar(0).ffbFinal` and moves its inertial needle using the absolute 0–100% magnitude. Its saturation warning briefly holds when the raw value reaches 98% or more. In replays or other contexts where physics telemetry is unavailable the needle parks at zero instead of substituting an estimate.

## License

[MIT](LICENSE)
