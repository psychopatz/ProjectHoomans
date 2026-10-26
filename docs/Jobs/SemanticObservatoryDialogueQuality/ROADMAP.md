# Semantic Observatory & Dialogue Quality Harness — full developer roadmap

**Parent goal: IN PROGRESS / PARTIALLY IMPLEMENTED.** These are mandatory developer-side phases P0–P7, not separate /goal assignments. A phase or Next Chunk passing is not completion of the parent goal. Current phase truth is reconciled in PROGRESS.md and must be updated from evidence rather than chronological notes.

## P0 — Baseline and canonical contracts
**Status: COMPLETE at audited ProjectHoomans 07aad881.**

- Reinspect working main, Core paired version, active registered sources and linked jobs; map response/flow/translation/suggestion ownership.
- Capture source/registry revisions; establish checked-in source versus generated artifact rules, current detail/trace gaps, production worker startup and no-write guarantees.
- Run focused real-worker inspector/flow/CodeBuilder/response checks and measure catalog payload, initialization, query, replay and memory baselines.
- Define schema-versioned, bounded, source-provenance and side-effect-free query contracts extending the existing worker protocol.

**Gate:** source→registration→render is evidenced for greeting, contextual question and a real registered action; representative baseline/performance measurements and no-write contracts are documented; no competing semantic authority exists.

## P1 — Read-only runtime catalog introspection
**Status: COMPLETE at audited ProjectHoomans 07aad881.**

- Enumerate actual loaded response pools/variants, conditions, priorities, template/plan summaries, revision and verified provenance from production Lua.
- Keep broad catalogs IDs+counts only; request details lazily with pagination/bounds.
- Preserve authored/generated/CodeBuilder/translation source distinctions. **Explicit UNKNOWN is an accepted provenance result when unique ownership cannot be proven.**
- Expose the same service to CLI and GUI.

**Gate:** loaded pool/variant details match production Lua; provenance is verified or explicitly UNKNOWN; reads are bounded/no-write and do not change runtime selection behavior.

## P2 — Explainable selection and authority provenance
**Status: ACCEPTANCE-PENDING. Core mechanism implemented.**

- Use the same Lua matching/scoring/tie/history path for optional explain traces; never reimplement selection in Python.
- Join selected variant/template/plan evidence to Conversation Inspector final text, translation chain, command/action result, effects and flow state.
- Distinguish condition mismatch, lower score, tie/hash, anti-repeat rotation and unavailable cases.
- For plan-turn/template-only responses, report exact source/variant only when proven; otherwise preserve bounded template candidates or UNKNOWN.

**Gate:** seeded and natural-history observed selections match explanations; explain does not mutate selection history or dispatch; source/authority joins never overclaim exact ownership.

## P3 — Human Studio: observability-first
**Status: ACCEPTANCE-PENDING. Catalog/Test/Coverage/Review surfaces implemented.**

- Keep Catalog, Test Lab, Coverage and Review as the readable observability-first surfaces inside the existing Semantic Lab.
- Search by topic/pool/flow/condition/owner and inspect actual variants, source/translation provenance and final rendered text.
- Keep raw JSON as an advanced view, not the primary user workflow.
- Preserve Advanced Flow graph/Build workflow/Dataset Library/Block palette/Interaction Composer.

**Gate:** a user can locate a real dialogue, understand selected/overridden variants and run its production-Lua scenario without manual JSON authoring; final GUI and CLI values agree.

## P4 — Grounded scenario matrix and quality coverage
**Status: IN PROGRESS.**

- Maintain bounded EN/TL matrices for personality/social style, relationships, hidden identity, weather/time, need/health, flow state, companion authority and negative permissions.
- Reset histories between unrelated cases; retain history intentionally for anti-repeat sequences.
- Report tested/untested, eligible/selected/lower-ranked/tied, fallback, contextual dominance, repetition/equivalence, translation mismatch, disclosure and unintended effects.
- Store compact fixtures/evidence; no unbounded NPC state or transcript duplication.
- **Mandatory remaining lifecycle proof:** construct a disposable save-backed player-owned faction and exercise the real worker Leave Group warning→confirmation→production ColonistDeparture path end to end. Existing unowned rejection and server/service-positive smokes do not replace this worker-level proof.

**Gate:** greeting/wellbeing/farewell/companion action and owned/unowned Leave Group behavior are reproducible in actual Core+Hoomans worker fixtures, with EN/TL where supported and explicit source/worker revision.

## P5 — Agent-first CLI/reporting
**Status: ACCEPTANCE-PENDING. Required commands implemented.**

- Keep stable headless catalog/detail/explain/turn/matrix/coverage/lineage/translation/proposal/compare operations routed through the same services as GUI.
- Emit schema-versioned bounded JSON/JSONL with limits, paging/truncation, fingerprints, sourceKind, exit codes and actionable errors.
- Maintain concise CLI documentation for ChatGPT via authorized desktop/repository access and local Codex.
- Close remaining wrong/unknown/stale/error, heavy-registry and GUI-parity cases. **Do not add more CLI surfaces unless a written acceptance gate requires one.**

**Gate:** an agent can discover/explain a pool, run EN/TL coverage and compare candidate/baseline behavior with bounded reports; final results match GUI/registered Lua.

## P6 — Safe delegated dialogue quality / variant workflow
**Status: IN PROGRESS. Preview/replay safety implemented; canonical promotion proof pending.**

- Retrieve actual source/variants, eligibility/plan/translation contracts and measured quality gaps.
- Treat generated language as a proposal. Preserve non-text metadata/side effects unless behavior change is separately authorized.
- Validate IDs/limits, Kahlua, EN/TL placeholders and meaning, grounding/disclosure, duplicates and flow/authority regression.
- Stage only outside watched media/user saves; run disposable real-Lua candidate replay and compare source fingerprints/effects.
- Promote only through the verified canonical owner (hand-authored Lua or CodeBuilder reviewed input), never by overwriting derived artifacts.
- Require an **explicit review decision** separate from proposal generation. The reviewer may be a human or authorized agent under this job, but must record why the text is semantically grounded/localized and cannot approve merely because it is grammatical.

**Gate:** one low-risk real response family is improved in EN/TL, explicitly reviewed, promoted to canonical source, replayed fresh from checked-in source, and shown to preserve selection metadata/gameplay effects.

## P7 — End-to-end developer acceptance, scale and handoff
**Status: IN PROGRESS. Several independent suites pass; consolidated final gate pending.**

- Exercise final P0–P6 flows in headless CLI and actual Tk GUI against production Lua/Core.
- Compare startup/query/replay/output/memory budgets to P0; respect current catalog/history caps unless separately justified.
- Run final focused+broad Python suites, full Lua suite, installed Project Zomboid Kahlua compiler, deterministic CodeBuilder writer parity, save/source hash safety and git diff checks.
- Verify no new source-of-truth duplication, watched-media staging, save writes or native/runtime publication side effects.
- Prepare user native SP/MP checklist only after every developer-implementable gate passes.

**Gate:** final real-Lua + GUI/headless parity + canonical source-patch regression + performance/data-safety evidence passes. Then set **READY FOR USER LIVE TEST**. Native SP/MP remains user-owned; after that acceptance the goal may become maintenance-ready.

## Closure order

1. P4A — positive player-owned Leave Group production-worker lifecycle.
2. P2/P3/P4/P5 — provenance/repeat/coverage and GUI↔CLI/error acceptance closeout without new feature creep.
3. P6 — one explicitly reviewed canonical EN/TL dialogue improvement and fresh-worker proof.
4. P7 — one consolidated developer acceptance pass and handoff.

## Continue / stop rule

After an accepted slice, update PROGRESS.md as concise current truth and continue automatically to the next mandatory closure slice. Do not append a historical diary and do not ask for a new /goal at phase boundaries. Stop only when the full developer objective is accepted, a genuine safety/authorization blocker prevents further work, or all implementable work is complete and only the user-owned native SP/MP gate remains.
