# Retro Engineering HUD

Retro Engineering HUD is a first-pass native CSP Lua app for Assetto Corsa. It is a single compact driving dial: the gear is the dominant read, with speed, RPM, a segmented limiter arc, steering marker, pedal bars, electronics, lights, and embedded turn indicators around it.

The visual system is adapted from the local Retro Engineering Console SimHub project: graphite surfaces, warm off-white Consolas text, amber instrumentation rules, and restrained cyan technical accents. No HUD code or artwork is copied from the installed reference apps.

## Install

Copy the `RetroEngineeringHUD` folder into:

```text
<Assetto Corsa>\apps\lua\RetroEngineeringHUD\
```

For the installation found during development, that is:

```text
D:\Games\steam dota\steamapps\common\assettocorsa\apps\lua\RetroEngineeringHUD\
```

Enable **Retro Engineering HUD** in Content Manager's Lua apps list, then add the app to the in-game app sidebar. The development copy can be deployed directly to the path above when wanted; unrelated AC/CSP files are not modified.

## CSP APIs and confirmed telemetry

The implementation follows the installed CSP Lua app conventions (`manifest.ini`, `script.update`, `script.windowMain`, `ac.storage`, and `require`). Drawing uses the installed API patterns `ui.drawCircle*`, `ui.drawRectFilled`, `ui.drawLine`, `ui.pathArcTo`, `ui.pathStroke`, `ui.pathFillConvex`, and `ui.dwriteDrawText`.

Confirmed from the local installed CSP apps/examples and used here:

- `ac.getSim()`
- `ac.getCar(0)`
- `car.speedKmh`, `car.rpm`, `car.rpmLimiter`, `car.gear`
- `car.steer`, `car.steerLock`, with `ac.getControllerSteerValue()` fallback
- `car.gas`, `car.brake`, `car.clutch`, `car.handbrake`
- `car.tractionControlModes`, `car.tractionControlMode`, `car.tractionControlInAction`
- `car.absModes`, `car.absMode`, `car.absInAction`
- `car.headlightsActive`, `car.lowBeams`
- `car.turningLeftLights`, `car.turningRightLights`, `car.hazardLights`, `car.turningLightsActivePhase`
- `car.isInPit`, `car.isInPitlane`

The app distinguishes configured TC/ABS levels from intervention state. A level is only displayed when the car reports a corresponding mode count; intervention highlighting only uses the actual `tractionControlInAction` / `absInAction` flags.

## Not reliably confirmed

The local installed examples do not rely on a `car.pitLimiter` field. The telemetry layer probes it safely and the PIT cell only uses it when present. Otherwise, `P` means the car is in the pit lane (`isInPit` / `isInPitlane`), not that a limiter is active. Engine limiter state is not fabricated.

## Debug and testing

Open the settings window and enable **Developer debug view**. The overlay exposes speed, gear, RPM, limiter source, steering, pedals, TC/ABS level and intervention state, lights, and optional pit-limiter state.

Suggested checks:

1. Load a GT3 with TC and ABS and verify both the numeric levels and intervention highlights.
2. Load cars without TC or ABS and verify the corresponding cell shows `—` instead of a fake zero.
3. Check an H-pattern car, a sequential car, and a mod car with a different RPM limiter.
4. Toggle lights and turn signals. The arrows stay embedded in the outer bezel and never occupy the upper center display.
5. Tune geometry in `src/layout.lua` and palette/type in `src/theme.lua`.

## Compact translucent presentation

The default window is intentionally compact (`460 × 460`) so it can sit beside the driving view rather than dominate it. Its settings window exposes independent HUD scale, instrument opacity and a translucent frosted backdrop.

CSP Lua apps can blend the dial with the running game, but the generic app API does not expose the already-rendered game frame for a safe true backdrop blur. The app therefore uses a real translucent, layered backdrop instead of rendering an expensive second scene that would not precisely match the active camera.

## Known limitations

- No in-game capture environment was available to verify pixel placement against a live car; the geometry is intentionally centralized for screenshot-driven iteration.
- CSP does not provide a confirmed pit-limiter field in the local examples used for this build, so the app degrades to pit-lane presence there.
- The app uses the vehicle-reported limiter when available and a configurable 8000 RPM fallback otherwise.
- This v0.1 intentionally excludes timing, relative, fuel strategy, tyre panels, maps, and other secondary race screens.
