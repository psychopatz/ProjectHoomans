# Handoff — Modular Semantic Harness and Mod Manager

updated_at: 2026-11-11T05:00:00Z
state: DIRTY_RESUMABLE
parent_status: ACTIVE
phase: P5
checkpoint: manager-and-provider-migration-verified
phase_commit: pending-participant-first-commits

## What is true

The goal is explicitly authorized. Core, Project Hoomans, and Dynamic Trading
are in scope. Existing unrelated dirty files were inspected and must be
preserved. Current provider/profile architecture and known combined-discovery
failure are recorded in ROADMAP, PROGRESS, and ARCHITECTURE.

## Resume action

Run final targeted checks, inspect exact diffs, commit Core first, Dynamic
Trading second, and Project Hoomans/job docs last. Preserve unrelated
architecture-audit and review changes.

## Acceptance

The harness is usable from Core in Core-only, PNC-only, DTAbstract-only,
DTHoomans-only, and PNC+DTHoomans selections; future expansion providers can
add v2 manifests and capability routes without Core code changes.
