# Roadmap — Modular Semantic Harness and Mod Manager

## Current phase status

- P0–P4: implemented and verified through source, manifest, route, launch,
  cleanup, and wheel checks.
- P5: active; focused Core/PNC/DT checks pass, while the unbounded aggregate
  PNC discovery run requires a separate existing-test hang investigation.
- P6: pending exact participant-first commits and final goal acceptance.

**Parent goal:** Make the PsychopatzCore Semantic Harness directly usable as a
manifest-driven, mod-agnostic composition harness for Core, Project Hoomans,
Dynamic Trading, and future expansion providers.

The completion boundary is developer-side: the harness launches from Core,
accepts enable/disable/switch selections, resolves dependencies and routes,
and passes the required provider matrix without native Project Zomboid or
Workshop publication.

| Phase | Mandatory acceptance |
| --- | --- |
| P0 — Baseline and contracts | Current trees, dirty-work boundaries, existing providers, launch commands, and focused test baselines are recorded. Provider/selection/route schemas are written before implementation. |
| P1 — Manifest discovery and resolution | Core discovers provider manifests without product-specific branches, validates schema, resolves dependencies/conflicts/load order, and emits a deterministic activation plan. |
| P2 — Selection manager CLI | Users can list providers/presets, select providers, enable/disable/switch selections, run doctor diagnostics, and launch Core-only, Project Hoomans-only, DTAbstract-only, and Project Hoomans+DTHoomans configurations. |
| P3 — Capability routing and runtime activation | Python and Lua workers consume the same activation plan; multi-provider selections route semantic and trading capabilities independently; optional providers degrade safely. |
| P4 — Provider cleanup and packaging | Generic harness mechanisms remain Core-owned, provider policy/content remains adopter-owned, duplicate launcher/config paths are removed or reduced to provider adapters, and wheel/installed execution works. |
| P5 — Regression and expansion proof | Existing Core/PNC/DT tests pass, selection negative cases pass, a synthetic future expansion manifest can be discovered and composed, and stale references/packaging gaps are addressed. |
| P6 — Final developer acceptance | Full applicable Python/Lua/Kahlua/CodeBuilder checks pass; four required selection modes are runnable from documented commands; exact phase-owned changes are committed locally in participant-first order. |

Phases are execution units, not the parent completion boundary. Continue through
all mandatory phases unless a concrete technical or authorization blocker is
encountered.
