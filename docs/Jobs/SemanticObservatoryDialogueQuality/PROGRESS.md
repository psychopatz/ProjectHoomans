# Semantic Observatory & Dialogue Quality Harness — current progress

**Status:** IN PROGRESS — Observatory foundations are real and usable; remaining work is acceptance closure, one canonical dialogue-quality promotion, and final integrated developer validation. **Parent goal remains NOT COMPLETE.**

**Current audited revisions (2026-10-26):**
- ProjectHoomans: `07aad881a9058e777c6e3ad62bb46ad0ec1216c7` on existing `main`, clean and synchronized with `origin/main`.
- PsychopatzCore: `cf28189c57f7810f31d25c46c11eb88080f47baa` on existing `main`, clean and synchronized with `origin/main`.

## Phase reconciliation

| Phase | Current state | Evidence / remaining gate |
| --- | --- | --- |
| P0 — Baseline/contracts | **COMPLETE** | Production source→registration→selection→translation/final-response chains, bounded query contracts, worker startup/query/memory baselines, no-write boundaries and real registered action evidence are established. |
| P1 — Runtime catalog | **COMPLETE** | Loaded pools/variants, conditions, priority, revision, bounded paging, translation/source metadata and verified CodeBuilder lineage exist. Legitimate unresolved provenance remains explicitly `UNKNOWN`; UNKNOWN is a valid result, not unfinished work. |
| P2 — Explain/provenance | **ACCEPTANCE-PENDING** | Production matcher/scorer/tie/history path owns explanation and does not consume selection history. Remaining closeout: response-plan/turn provenance must be exact where provable and explicitly UNKNOWN/template-only where not; rerun natural-history parity and negative cases as one acceptance slice. |
| P3 — Studio observability | **ACCEPTANCE-PENDING** | Existing Semantic Lab now has Catalog/Test/Coverage/Review surfaces backed by the real worker; Tk/Xvfb tests have passed. Remaining closeout: explicit GUI↔CLI parity/regression acceptance across the final contracts. |
| P4 — Grounded coverage | **IN PROGRESS** | EN/TL greeting, wellbeing/health, hidden identity, Follow/Stay, permission rejection, Goodbye and unowned Leave Group fixtures exist. Missing mandatory proof: positive player-owned Leave Group warning→confirm→departure through the production worker; deliberate repeat/dominance/equivalence coverage also needs final consolidation. |
| P5 — Agent CLI | **ACCEPTANCE-PENDING** | Headless discover/detail/explain/turn/matrix/coverage/lineage/translation/proposal/compare paths exist with bounded JSON/JSONL. Remaining closeout: final wrong/stale/unknown/error/scale and GUI parity matrix; do not add new commands unless a remaining gate requires one. |
| P6 — Delegated variant workflow | **IN PROGRESS** | Stale SHA/fingerprint checks, external staging, EN/TL isolated production-Lua replay, zero production writes and source/translation diffs are proven. Missing gate: one explicitly reviewed canonical response improvement promoted to its true source owner and replayed fresh with unchanged gameplay effects. |
| P7 — Integrated acceptance | **IN PROGRESS** | Scale measurements, full Lua suite, Kahlua compilation and several Tk/worker suites have independently passed. Missing gate: one consolidated end-to-end acceptance over the final P0–P6 state, including save-read-only proof, GUI/CLI parity, CodeBuilder determinism and final performance comparison. |

## Current verified evidence

Fresh independent audit on ProjectHoomans `07aad881`:

- **65 Python tests PASS, 2 SKIP** across Observatory, matrices, CodeBuilder lineage, translation coverage, scale, Kahlua verifier, Conversation Inspector, runtime graph, CodeBuilder consolidation and semantic response regression modules.
- Bundled lifecycle matrix: **8/8 PASS** for EN/TL root Goodbye, typed-goodbye distinction, Follow→Wait and unowned/unknown-faction Leave Group rejection.
- Production Lua focused authority/conversion smokes: **3/3 PASS** for conversation departure authority, colonist departure conversion and companion commands.
- Worktree and upstream were clean/synchronized; `git diff --check` passed.

Recorded implementation evidence already present in repository history (not rerun in the audit above):

- Full Lua smoke suite **889/889 PASS** after fixture-bootstrap corrections.
- Project Zomboid Kahlua compiler verification **119/119 PASS** for the bounded Observatory/semantic/social-flavor scope.
- Real Tk/Xvfb Observatory Catalog/Review/Coverage tests passed against the production Lua worker.
- Fresh worker catalog stabilized at **129 pools**, revision **205**; sampled startup about **824–844 ms**, RSS/HWM about **31.7–32.1 MB**.
- Isolated greeting candidate preview demonstrated EN/TL before/after text through disposable real Lua workers with identical selected keys/action/transport counts and zero production writes.
- Follow/Stay default EN/TL translation fallback defect was repaired in existing manifest-owned catalogs; this is localization correctness evidence, **not** the required P6 quality-promotion demonstration.

## Immediate Next Chunk — P4A positive owned-faction Leave Group worker lifecycle

This is developer-side work and **must not be treated as blocked by a denied exploratory remote command**.

Reuse the existing synthetic save / production rehydration infrastructure (including the patterns in `test_production_faction_rehydration_p14c.py`) to construct a disposable source where:

1. production `PNC_PlayerCharacters.Load` resolves the worker player to a stable player entity key;
2. production `PNC.Factions.LoadRaw` hydrates a non-mobile player faction whose `ownerPlayerKey` equals that entity key;
3. the recruited NPC's persisted affiliation points to that same faction and membership is internally consistent;
4. the real worker opens the conversation root and exercises the existing Leave Group / departure warning and confirmation route;
5. the actual `PNC.ColonistDeparture` service performs the positive transition rather than a substituted executor seam.

**P4A acceptance:**
- warning path returns the production warning response and performs no departure mutation;
- confirmation returns `response.departure.confirmed` / `colonist_departed`, closes the conversation exactly once, clears recruited/player ownership, removes the NPC from the source player faction, places it in the production departure destination/mobile faction, and preserves the real relationship-penalty audit;
- EN and TL presentation are verified where the same production route supports them;
- no source save bytes are modified; temporary fixture hash is unchanged; no watched-media staging, native PZ launch or Workshop action;
- negative unowned/other-owner cases remain passing.

After P4A, **continue automatically** through the remaining acceptance slices below. Do not stop for another /goal.

## Required closure sequence after P4A

1. **P2/P3/P4/P5 closeout:** consolidate plan-turn/source provenance, deliberate repeat/dominance/equivalence coverage, and final GUI↔CLI/error/scale parity. Legitimate UNKNOWN/template-only provenance is acceptable when evidence cannot identify a unique owner; never invent ownership to force a green gate.
2. **P6 canonical proof:** choose one low-risk authored greeting/response family with verified ownership; produce an EN/TL improvement, run proposal review + stale guards + isolated real-Lua before/after, record an explicit review decision, edit the canonical source only, then fresh-worker replay the checked-in result. Preserve all `when`/priority/plan/authority metadata and prove gameplay effects are unchanged.
3. **P7 integrated acceptance:** run the final relevant Python suites, full Lua suite, installed PZ Kahlua compiler, Tk/Xvfb Observatory surfaces, headless CLI parity/error cases, deterministic CodeBuilder writer checks, save/source hash safety, performance comparison and `git diff --check`.
4. Only after all developer gates pass, set **READY FOR USER LIVE TEST** and hand the remaining native SP/MP verification to the user.

## Scope and stop rules

- Do **not** feature-creep the Observatory or add commands merely to create more evidence. Prefer closing written gates with the existing surfaces.
- Do **not** chase every UNKNOWN source result. UNKNOWN is correct when ownership cannot be proven.
- Do **not** append historical continuation sections to this file. Replace it with current truth when state changes; Git history is the archive.
- Do not modify root `AGENTS.md`, create a new branch, launch native Project Zomboid, edit source saves, or publish Steam Workshop content.
- Stop only when the entire developer-side parent goal is accepted, a genuine safety/authorization blocker prevents further work, or the only remaining gate is the explicitly user-owned native SP/MP test.
