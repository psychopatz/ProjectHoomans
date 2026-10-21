# Roadmap — one complete implementation objective
Status: ALL PHASES PLANNED; acceptance not yet claimed. Phase milestones are progress checkpoints, not permission to declare the goal finished.
## S0 — source ownership & actual UI/worker baseline
Audit current Hoomans/Core APIs, dialogue input widget/reply presentation, FlowKernel, candidate parser, action dispatcher, Core actor/relationships, EN/TL catalogs, and Semantic Lab scenario projection/inspector. Capture one real-worker before-state for typed and reply turns and document integration points. Avoid duplicating available systems.
Gate: source paths, current actual message/button UI semantics, authority route and real Lua worker reproduced; remaining deltas explicit.
## S1 — canonical suggestion contract and candidate sources
Register stable typed candidate definitions and sources from player interpreted frame, NPC response plan, active flow and permitted capability descriptors. Implement deduplication, bounded ranking and stable IDs/turn revisions; no keyword-only NPC reply reparse.
Gate: real Lua worker produces meaningful typed/reply options, bounded and repeatable; no effects merely from suggestion generation.
## S2 — generic constraints and domain providers
all/any/not, typed predicates, reason codes, fail-closed unavailable providers, trait/identity/relationship/knowledge/state/dialogue/inventory/capability admission using existing public owners; distinguish visibility and eligibility; private-info redaction.
Gate: boundary values, unknown, stale and secret/romance/privacy matrix; eligible suggestions ranked deterministically without leaking restricted data.
## S3 — complete click pipeline
Canonical semantic frame transport, visible localized player utterance, flow/policy integration, server-side recheck, replay protection and exact-once side-effect ownership; typed/button parity; stale/denied clicks safe.
Gate: actual worker exercises selectable response through existing production dialogue/action adapters, no duplicate follow/gift/item/relationship effects.
## S4 — in-game UI and EN/TL
Show after submitted player text and after NPC replies, plus optional debounced partial-input suggestions (do not block or rewrite free typing). Responsive layout with 3–5 context-relevant options, accessible enabled/disabled semantics, refresh on new turn and NPC switch; translation resolves through registered Core-backed catalogs.
Gate: existing client window actually renders/clicks, all labels and utterances use correct EN/TL, no stale NPC/turn or per-frame NLP.
## S5 — first-class existing Semantic Lab integration
Editable scenario facts and relationships, visual suggestion panel, candidate/constraint/rank/provenance inspector, click-to-advance through production Lua, codeblock authoring bridge where appropriate, replay fixtures, redacted trace artifacts. No standalone toy demo.
Gate: GUI/Xvfb proof of *existing* Tk UI and real Lua worker end-to-end after edits; generated artifact placement and registered translation proven.
## S6 — acceptance/performance/handoff
Full focused + impacted Lua/Python suites, doctor/Kahlua, real-worker EN/TL and privacy matrix, bounded responsiveness/load, single/multi-party semantics, SP/MP authority review. Fix regressions before handoff.
Gate: all developer-verifiable gates green with artifacts. Final status READY FOR USER LIVE TEST only; native PZ SP/MP and actual installation are user-owned acceptance and must be marked UNTESTED when not run. Never require Workshop publication.
## Operating rule
Agent must continue S0→S6 autonomously as each gate passes, committing coherent working slices on existing main after safe synchronization; do not stop simply because one phase completed. No speculative feature scope or unauthorized publication.