# Roadmap — Semantic Harness UI Runtime Parity

Parent status: implementation complete for the developer-side harness.

Primary repository: ProjectHoomans

Participant repositories: psychopatzCore, DynamicTrading

## Completion contract

PsychopatzCore owns the executable harness, launcher, GUI composition, tabs,
worker/session lifecycle, inspection, CodeBuilder framework, generic fixtures,
testing utilities, and provider-neutral contracts. Project Hoomans and Dynamic
Trading contribute provider manifests, policy, production adapters, and
provider content only. No adopter may carry a second launcher or Semantic Lab
implementation.

The restored GUI must preserve the old working surface from
`4659cfe19c4bb60ac350b04a299458770ec5bc70`: Simulation, Quality Sweep,
Studio, Log, World Browser, nested authoring/inspection tabs,
conversation/workbench panes, semantic trace, suggestions, saved-world
browsing, replay/regression controls, and layout persistence.

## Phases

### P0 — Recovery inventory

Complete. The old commit, the minimal Core shell, the stranded PNC copy, and
all three worktree states were audited without overwriting unrelated changes.

### P1 — Core package recovery

Complete. The full UI, Studio, inspection, testing, CodeBuilder, fixture, and
Core-facing runtime implementation now lives under
`psychopatzCore/tools/semantic_harness/`. PNC’s duplicate `lab` and
`codebuilder` trees were removed.

### P2 — GUI and worker compatibility

Complete. The Core app preserves GUI-by-default behavior, uses the provider
manager and worker facade, exposes provider-neutral titles, and launches Core,
PNC, and DTAbstract modes. PNC semantic identity input and suggestions were
verified after the migration.

### P3 — Provider composition

Complete for the harness layer. Presets and manifests resolve Core-only,
Project Hoomans, DTAbstract, DTHoomans, and combined PNC+DTHoomans selections.
The PNC manifest now points at Core’s canonical Conversation manifest.

### P4 — Acceptance and handoff

Developer-side acceptance is complete. Core tests, focused migrated provider
tests, headless matrix checks, and fresh GUI launches pass. Native Project
Zomboid live validation remains user-owned and is not part of this change.

## Commit gate

Review and commit only goal-owned paths: Core first, then Project Hoomans.
Preserve unrelated dirty audit files, do not create a branch, and do not
publish Workshop content.
