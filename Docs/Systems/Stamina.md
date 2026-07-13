# Stamina

## Purpose
- `PNC_Stamina` owns authoritative stamina values, recovery, combat spend rules, and overhead-visibility timers.

## Current Rules
- melee, ranged, and downed shove actions spend stamina through one authority path
- skill-aware attack spend can reduce effective stamina cost
- recovery differs for idle, moving, combat, and downed states
- tactical retreat can temporarily opt into idle-rate stamina recovery while moving away from danger
- movement stamina now tracks fake-locomotion exhaustion separately from attack spend and can downgrade run into recovery walk or recovery sneak instead of hard-stalling movement
- movement exhaustion uses hysteresis and a short sprint breather so run can resume only after both stamina recovery and the breather lock clear
- nameplates decide draw visibility from stamina summary data, not direct runtime internals
- the overhead stamina bar uses a smooth dark-gray-to-white gradient so it remains visually distinct from HP's green/yellow/red states

## Integration Points
- `PNC_Combat_*` checks and spends attack stamina
- `PNC_LocomotionProfiles` and `PNC_PathService` consume movement stamina profile output when resolving live-body transport
- `PNC_Network` exports stamina summary and visibility data
- `PNC_Nameplates` uses stamina snapshot lanes for overhead bars

## Forbidden Responsibilities
- does not select jobs
- does not decide target acquisition
- does not build full UI windows
