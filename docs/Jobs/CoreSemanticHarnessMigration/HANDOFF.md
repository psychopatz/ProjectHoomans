# Core Semantic Harness Migration Handoff

updated_at: 2026-11-11T00:00:00Z
state: COMPLETE_DEVELOPER_SIDE
phase: Phase 5 — hard deletion and verification
checkpoint: Core and DynamicTrading participant commits are complete; the
ProjectHoomans primary commit contains this handoff and the provider cutover.

accepted:

- Core is the sole Semantic Harness owner and package entrypoint.
- ProjectHoomans and DynamicTrading old harness trees and root harness metadata
  are deleted.
- Shared identity/nickname/display, static-suggestion, and radio/discovery
  contracts are Core-owned and generated from the Core/provider manifest model.
- DTAbstract is independently resolvable with Core and DT; PNC is not required.
- Focused Python/Lua suites, generator regeneration, and deletion scans pass.

user_owned_next_step: Load the enabled mod combinations in Project Zomboid and
exercise PNC identity disclosure, DTAbstract trader dialogue, and radio/world
discovery in SP/MP as appropriate. No Workshop publication was performed.
