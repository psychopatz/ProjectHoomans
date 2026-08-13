# PNC Live Body Control

## Purpose

`PNC_LiveBodyControl.lua` owns embodied zombie-body suppression for live NPCs.
It keeps zombie-only state cleanup out of behavior code and out of the shared
locomotion lane.

## Ownership

- `PNC_Behavior_*`: publish movement intent only.
- `PNC_PathService`: owns the shared movement lane, move diagnostics, goal
  stickiness, special movement coordination, and the canonical record-first
  reset command.
- `PNC_LiveBodyControl`: owns suppression of zombie-only body states such as
  lunge, sit-on-ground, get-up, stagger, and emitter silencing.
- `PNC_Animation`: reuses `PNC_LiveBodyControl` when preparing a live body.
- `PNC_FakeLocomotion`: relies on this module before every controlled step.

## Rules

- Do not add per-behavior locomotion again.
- Do not bury live-body suppression back into `PNC_PathService` or animation.
- Avoid `pcall` for normal engine integration; prefer explicit guards and
  stable call sites.
- Live embodied NPCs are expected to remain `setUseless(true)` while fake
  locomotion owns movement.
- Native-path and scripted-action leases temporarily require
  `setUseless(false)`; `PNC_LiveBodyControl` is the only policy writer that
  transitions between these modes.
- Changes must remain authority-safe for both singleplayer and multiplayer.

## Runtime Data

`record.runtime.pathing` remains the shared movement lane. `PNC_LiveBodyControl`
may read and update only lane fields needed for suppression throttles, such as
`lastSuppressAudioAt`.

## Current Responsibilities

- Apply live-body anti-zombie flags such as `NoLungeTarget` and
  `NoLungeAttack`.
- Enforce `isUseless`, no teeth, and cleared target/aggro from
  `OnZombieUpdate` before the remainder of vanilla AI; world-ready scans cover
  loaded bodies before normal reconciliation.
- Clear crawler, fake-dead, floor, and alert state drift.
- Silence moans and other emitter output on a throttle.
- Force lunge/get-up/stagger style states back to idle when encountered.
- Release damage reactions through their real ActionContext exit signals:
  clear `bStaggerBack`, zero `stateEventDelayTimer` for stagger states, and
  report `ActiveAnimFinishing` for hit-reaction states. The legacy AI
  `changeState(ZombieIdleState)` API must not be used for these states because
  entering that AI state resets the same delay timer used by ActionContext.
- Support the fake-locomotion owner by keeping the embodied body in a stable
  non-zombie state before each server-authoritative movement step.
- Apply PNC-authored transforms through `SetAuthoritativePosition`, keeping the
  engine previous-position fields aligned so controlled movement is not
  reprocessed as a Java collision or vanilla traversal.
