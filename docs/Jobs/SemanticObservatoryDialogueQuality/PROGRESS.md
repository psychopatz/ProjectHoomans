# Semantic Observatory & Dialogue Quality Harness — current progress

**Status:** IN PROGRESS — the developer-side parent goal is not complete. Observatory/runtime foundations, P4A Leave Group proof and the first canonical dialogue promotion are accepted in the current worktree; the user has now added a mandatory Dialogue Content Registry / phrase-variation slice plus final acceptance closeout.

**Current audited revisions (2026-10-26):**

- ProjectHoomans: `8cebde57161cb197b4ebbfd8e45544f1dd51c8b6` on existing `main`, matching `origin/main` before the current worktree changes.
- PsychopatzCore: `cf28189c57f7810f31d25c46c11eb88080f47baa` on existing `main`, matching `origin/main`.
- The current worktree is intentionally dirty with the in-flight P3 surface consolidation, accepted P4A worker/rehydration proof, accepted P6 greeting promotion, tests, and the newly approved documentation direction. Reconcile before writing; do not reset/stash/discard it. No source save, watched-media staging, native Project Zomboid launch, or Workshop operation is authorized by this goal.

## Phase reconciliation

| Phase | Current state | Evidence / remaining gate |
| --- | --- | --- |
| P0 — Baseline/contracts | **COMPLETE** | Production source→registration→selection→translation/final-response chains, bounded query contracts, worker startup/query/memory baselines, and no-write boundaries are established. |
| P1 — Runtime catalog | **COMPLETE** | Loaded pools/variants, conditions, priority, revision, bounded paging, translation/source metadata, and CodeBuilder lineage are verified. Legitimate unresolved provenance remains `UNKNOWN`; that is an accepted result. |
| P2 — Explain/provenance | **ACCEPTANCE-PENDING** | Production matcher/scorer/tie/history owns explanation and does not consume selection history. Closeout still needs the final response-plan/turn provenance and natural-history negative acceptance slice; exact ownership must remain `UNKNOWN` where it cannot be proven. |
| P3 — Human UI/content surface | **IN PROGRESS** | Simulation/Studio redundancy consolidation is implemented in the worktree, but the newly approved target is now `Explore + Dialogue Content + Review`; structural editors must move behind Developer Tools and the Dialogue Content surface still needs implementation/acceptance. |
| P4 — Grounded scenario matrix | **ACCEPTANCE-PENDING** | Existing EN/TL, identity, wellbeing/health, follow/stay, permission, goodbye, and repeat/dominance/equivalence fixtures remain in scope. P4A is accepted below; final matrix consolidation remains. |
| P5 — Agent CLI | **ACCEPTANCE-PENDING** | Existing bounded catalog/detail/explain/turn/matrix/coverage/lineage/translation/proposal/compare JSON/JSONL paths remain the authority. Closeout still needs final wrong/stale/unknown/error/scale and GUI-parity evidence; no new command is currently required. |
| P6 — Delegated quality + phrase registry | **IN PROGRESS** | The original one-family authored greeting promotion is **accepted** and retained below. The newly approved Dialogue Content Registry / post-style phrase-variation capability is now mandatory and not yet implemented/accepted. |
| P7 — Integrated acceptance | **IN PROGRESS** | Final Python/Lua/Kahlua/Tk/Xvfb/CLI/CodeBuilder/hash/performance acceptance is still pending after P2–P6 closure. |

## Accepted P4A slice

`tools/semantic_harness/tests/test_production_leave_group_p4a.py` now has **4/4 PASS** through the real production worker route using a disposable synthetic save:

- the production player registry resolves the player entity key;
- `PNC.Factions.LoadRaw` rehydrates a non-mobile player-owned faction with matching `ownerPlayerKey`, and the recruited NPC is a member;
- open conversation → Leave Group → production warning is mutation-free → confirmation reaches actual `PNC.ColonistDeparture`;
- confirmation emits `response.departure.confirmed` / `colonist_departed`, closes once, clears recruited/player ownership, removes the NPC from the source faction, and places it in the real refugee/mobile destination;
- relationship before/after/delta, permanent `colonist_expelled` memory, and interaction-journal evidence are retained;
- EN and TL presentation are verified on the same route;
- unowned and other-owner cases are rejected without mutation; source worker snapshots and temporary save bytes remain unchanged.

The production-worker adapter now carries the canonical production composer context into the headless conversation spec, and refreshed projections re-read the post-departure production faction so destination/mobile state is observable. Production Lua/Core remain semantic and gameplay authority.

## Accepted P6 promotion

The reviewed family is `semantic.flow.greeting.opening.default`. The production catalog reports `AUTHORED_LUA` ownership at `Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Semantics/SemanticDialogueResponseCatalog/PNC_SemanticDialogueResponseCatalog_FlowGreeting.lua`; EN/TL text owners are the unique manifest-listed `Conversation/Semantic/Responses.json` assets.

The generated proposal changed only the greeting text: EN `Hello. Good to see you.` → `Hey there. Good to see you.` and TL `Kumusta. Mabuti at nakita kita.` → `Uy, mabuti at nakita kita.`. Review decision: **APPROVE**. The decision is grounded in the same neutral greeting context, preserves the meaning and friendly register in both languages, has no placeholders or fabricated facts, and leaves `when=[]`, priority `0`, the two-turn `GREETING_OPENING` plan, selected ID, authority route, actions, and transport unchanged. The isolated real-Lua preview passed EN/TL with `writesToProduction=0`, `candidateOverlayCleaned=true`, stale content/source guards, and `unchangedGameplayEffects=true`; a fresh checked-in worker replay passed the corresponding promotion test.

## Newly approved dialogue-content direction

The product gap changed after the initial P6 promotion proved safe canonical text editing. Studio should no longer expose structural semantic authoring as the normal human workflow. The durable target is documented in `DIALOGUE_CONTENT_REGISTRY.md`:

- agents/code own semantic flows, conditions, priority, plans, actions and authority;
- ResponseCatalog selects **semantic/context variants**;
- SpeechRealization selects style;
- a new bounded phrase layer selects equivalent wording with deterministic immediate-repeat avoidance;
- phrase arrays are **not** stored directly in PsychopatzCore translation JSON — CodeBuilder emits ordinary string-valued EN/TL keys plus compiled phrase-family metadata;
- Studio becomes `Explore + Dialogue Content + Review`; structural editors are Developer Tools;
- NPC phrases may vary dynamically, while player landing/navigation labels remain stable by default and only their content is editable with route/hub/concept/eligibility locked.

The first migration must prove one existing family is behavior-equivalent before adding 3+ EN/TL phrases, then expose semantic variant + style + phrase ID separately through the real worker/Simulation/CLI.

## Required closure sequence

1. Preserve and finish validating the current P3 surface-consolidation/P4A/P6 worktree; the accepted Leave Group and first greeting-promotion evidence must not be redone or lost.
2. Implement the new P3/P6B content direction: Studio `Explore + Dialogue Content + Review`, structural Developer Tools, canonical Dialogue Content source/compiler, separate post-style phrase selection, and one behavior-equivalent greeting-family migration followed by 3+ EN/TL phrases with anti-repeat proof.
3. Prove one verified player landing/choice content edit with route/hub/concept/eligibility locked and stable-label behavior.
4. Close remaining P2/P4/P5 provenance/repeat/coverage and GUI↔CLI/error/scale gates. Do not eliminate legitimate `UNKNOWN` values.
5. Run one consolidated P7 acceptance pass: final Python suites, full Lua suite, installed Project Zomboid Kahlua compiler, actual Tk/Xvfb surfaces, headless CLI parity/error paths, deterministic CodeBuilder/content generation, save/source hash safety, performance comparison, and `git diff --check`.
6. Only when every developer-side gate passes, set **READY FOR USER LIVE TEST**. Native SP/MP verification remains explicitly user-owned.

## Scope and stop rules

- Do not feature-creep the Observatory or add commands unless a remaining written acceptance gate requires one.
- Do not modify root `AGENTS.md`, create branches, launch native Project Zomboid, edit source saves, publish Workshop content, or overwrite concurrent changes.
- Do not append chronological continuation sections; replace this current truth when status changes.
- Stop only when the developer-side parent goal is accepted, a genuine technical/safety/authorization blocker prevents implementable work, or only the explicitly user-owned native SP/MP test remains.
