# Roadmap — one complete implementation objective
Status: DEVELOPER-SIDE S0–S6 COMPLETE, including the semantic-first production root presentation migration; native Project Zomboid SP/MP live acceptance remains UNTESTED and user-owned. Phase milestones remain evidence checkpoints, not release authorization.
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

## Completed migration slice

The final presentation slice makes the existing dynamic production root the default semantic button source. It covers authored topic categories, identity/system choices, owned-companion choices, topic grouping, EN/TL labels, native Core choice-part compatibility, worker root inspection, and real root-to-dialogue transitions. The current production adapter reuses Core's single scrollable `choicesPart`; it does not register a second Hoomans button-grid surface or impose a five-row UI cap. The worker/UI readiness handoff and layout regressions are covered by the existing S4 tests.

Developer-side evidence is recorded in `PROGRESS.md`: the latest focused Xvfb GUI acceptance passed 4/4, contextual worker suites passed 12/12, relevant inventory/task/choice Lua regressions passed 8/8 plus the focused GIVE smoke, doctor required checks passed, and changed PZ Lua Kahlua/`luac5.3` checks found no issues. Hoomans `708d7296` and Core `ba60095` are local commits on `main`; neither repository was pushed. The only remaining gate is user-run native PZ SP/MP acceptance.

## Final phase correction — 2026-10-22

S0–S6 are complete on the current implementation revisions Hoomans `96228bfbd814147d71998416306711395227a9eb` and Core `443b3a86d097b8fd17fa10caafa545f959dc913f`. The final migration uses Core's existing native `choicesPart` through one generic presentation callback; the temporary/competing Hoomans button-grid surface is not part of the production path. Core owns the reusable UI mechanics, while Hoomans owns semantic groups, privacy policy, eligibility, typed frames, and existing action dispatch.

The selected topic group is the dynamic branching boundary. Its typed group frame changes projection only; candidate/action frames are the only clickable semantic execution requests and still pass preflight plus click-time authority checks. All production rows in the selected bounded group are presented through Core's scrollable list, so the Semantic Lab has no artificial five-button limit. The existing production candidate bound and privacy-safe fail-closed predicates remain in Lua policy.

Final developer-side evidence is recorded in `PROGRESS.md`: contextual worker tests **35/35**, Xvfb GUI acceptance **5/5**, focused production Lua regressions **8/8**, Core smoke pass, changed-slice Kahlua/`luac5.3` pass, doctor required checks pass, and bounded worker performance pass. The broader worker discovery timeout is recorded as a known orchestration/teardown limitation, not hidden as a green result. Native PZ SP/MP and live `GIVE` are **UNTESTED** and remain the user handoff gate. No push, release, or Workshop action is authorized or taken.
