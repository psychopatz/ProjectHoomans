# Semantic Observatory & Dialogue Quality Harness — full developer roadmap

**Parent goal: IN PROGRESS — P3/P7 REOPENED by live startup/session parity findings.** These are mandatory developer-side phases P0–P7, not separate /goal assignments. Native Project Zomboid SP/MP verification remains user-owned only after the reopened developer-side gates pass; current phase truth is reconciled in PROGRESS.md from evidence rather than chronological notes.

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
**Status: COMPLETE.**

- Use the same Lua matching/scoring/tie/history path for optional explain traces; never reimplement selection in Python.
- Join selected variant/template/plan evidence to Conversation Inspector final text, translation chain, command/action result, effects and flow state.
- Distinguish condition mismatch, lower score, tie/hash, anti-repeat rotation and unavailable cases.
- For plan-turn/template-only responses, report exact source/variant only when proven; otherwise preserve bounded template candidates or UNKNOWN.

**Gate:** seeded and natural-history observed selections match explanations; explain does not mutate selection history or dispatch; source/authority joins never overclaim exact ownership.

## P3 — Human UI surface consolidation
**Status: REOPENED / IN PROGRESS (P3C).** Core ownership consolidation and P3B startup/session behavior are functionally accepted. P3C Test Isolation & Runtime Performance is now mandatory because P3B made persisted SAVE intent operational at startup and exposed non-hermetic GUI tests plus an impractically slow Xvfb acceptance loop.

- Enforce the ownership contract in SURFACE_CONSOLIDATION.md: Simulation executes/tests; Studio is Explore + Dialogue Content + Review; World Browser selects persisted targets; Log owns activity history.
- Remove Studio Observatory Test Lab as a parallel conversation runner. All interactive fixture/save-backed execution now routes through Simulation.
- Move/consolidate human-facing Observatory Coverage/regression actions into Simulation Compare/Regression while preserving shared matrix services and headless CLI.
- Merge read-only Observatory Catalog + Interaction Explorer + useful source-browser responsibilities into Studio **Explore**. Keep context-specific “why did this win?” inspection in Simulation; Explore shows static rules/source metadata.
- Add Studio **Dialogue Content** using DIALOGUE_CONTENT_REGISTRY.md: edit canonical content-only EN/TL phrase families and verified player landing/choice wording while semantic/route/authority fields remain locked; preview only through Simulation.
- Redesign Studio **Review** around human-readable candidate before/after, EN/TL, source owner, invariant/effect checks and explicit review decision; it may reuse disposable worker services without becoming another simulator.
- Move Flow Graph editing, raw canonical JSON editing, Block Palette/contracts, Interaction Composer and Build Workflow behind **Developer Tools**, not a peer Studio workflow. Treat Build Workflow as Legacy/retirement candidate; remove dead duplicate UI only after proving no unique capability/caller remains.
- Consolidate Simulation diagnostics toward **Inspect | Graph | Compare/Regression | World | Debug** using existing controllers/widgets; do not create replacement semantic inspectors.
- Preserve safe UI-state migration and agent CLI parity.

**Gate:** one user task has one GUI home; no duplicate Studio runner/context/coverage surface remains; Studio defaults to Explore + Dialogue Content + Review, structural authoring is Developer Tools; Simulation retains all runtime/testing capability; World Browser/Log remain sole owners; Dialogue Content can safely edit one canonical phrase family and one verified landing/choice text with locked structural metadata; moved/retired functions pass real-worker Tk/Xvfb and CLI parity regression without semantic or save behavior changes.

**P3B startup/session addendum:** visible Response Channel rows must be empty before native conversation open and thereafter exactly match production `conversationPresentation.responseChannel`; remembered active SAVE source/player/NPC must auto-restore across Semantic Lab application launches using existing read-only import logic; Studio Explore must populate its first bounded catalog page automatically on worker-ready; stale remembered targets fall back safely to FIXTURE. See SURFACE_CONSOLIDATION.md.

**P3C performance/test-isolation addendum:** preserve all P3B behavior while making GUI tests hermetic from real user UI/SAVE state, keeping background Explore loading local rather than globally busy, using condition-specific bounded waits, and splitting full headless regression from focused Xvfb GUI acceptance. See TEST_RUNTIME_PERFORMANCE.md.

## P4 — Grounded scenario matrix and quality coverage
**Status: COMPLETE.**

- Maintain bounded EN/TL matrices for personality/social style, relationships, hidden identity, weather/time, need/health, flow state, companion authority and negative permissions.
- Reset histories between unrelated cases; retain history intentionally for anti-repeat sequences.
- Report tested/untested, eligible/selected/lower-ranked/tied, fallback, contextual dominance, repetition/equivalence, translation mismatch, disclosure and unintended effects.
- Store compact fixtures/evidence; no unbounded NPC state or transcript duplication.
- **Accepted lifecycle proof:** the disposable save-backed player-owned faction fixture exercises the real worker Leave Group warning→confirmation→production ColonistDeparture path end to end; unowned/other-owner rejection remains covered.

**Gate:** greeting/wellbeing/farewell/companion action and owned/unowned Leave Group behavior are reproducible in actual Core+Hoomans worker fixtures, with EN/TL where supported and explicit source/worker revision.

## P5 — Agent-first CLI/reporting
**Status: COMPLETE.** Required commands and bounded error/scale/parity paths are verified.

- Keep stable headless catalog/detail/explain/turn/matrix/coverage/lineage/translation/proposal/compare operations routed through the same services as GUI.
- Emit schema-versioned bounded JSON/JSONL with limits, paging/truncation, fingerprints, sourceKind, exit codes and actionable errors.
- Maintain concise CLI documentation for ChatGPT via authorized desktop/repository access and local Codex.
- Close remaining wrong/unknown/stale/error, heavy-registry and GUI-parity cases. **Do not add more CLI surfaces unless a written acceptance gate requires one.**

**Gate:** an agent can discover/explain a pool, run EN/TL coverage and compare candidate/baseline behavior with bounded reports; final results match GUI/registered Lua.

## P6 — Safe delegated dialogue quality + dynamic phrase registry
**Status: COMPLETE.** The original canonical promotion and the Dialogue Content Registry / phrase-variation extension are accepted.

- Preserve the existing safe proposal/review workflow: retrieve verified source/translation contracts, use stale guards, stage outside watched media/user saves, run disposable real-Lua before/after, and require an explicit review decision.
- Implement DIALOGUE_CONTENT_REGISTRY.md through existing CodeBuilder ownership: one canonical content-only source, deterministic generated Lua phrase metadata, and normal string-valued EN/TL translation keys/manifests.
- Keep ResponseCatalog semantic/context variants separate from equivalent wording. Do not consume semantic variant slots merely for synonyms.
- Extend the owned SpeechRealization seam so phrase selection occurs after semantic selection + style resolution, with bounded deterministic immediate-repeat avoidance and observable phrase ID/pool metadata.
- Studio Dialogue Content edits canonical phrase content, not `when`, priority, plan, route, action or authority metadata. Raw generated Lua/translation artifacts are not the editing surface.
- Migrate one low-risk response family first with behavior-equivalent generated output, then add 3+ EN/TL phrase variants and prove unchanged semantic selection/gameplay effects.
- Add one verified player landing/choice content edit (for example the What's Up landing text) while candidate ID, route, hub/concept and eligibility remain locked and labels stay stable by default.
- Audit old ToolReplies/SocialFlavor wording only for later consolidation opportunities; do not wholesale delete/migrate them without parity evidence.

**Gate:** the prior canonical promotion remains valid **and** the Dialogue Content Registry acceptance in DIALOGUE_CONTENT_REGISTRY.md passes: deterministic CodeBuilder generation, string-only translations, separate semantic/style/phrase identities, 3+ EN/TL phrases with anti-repeat real-Lua proof, Studio content editing with stale guards, one locked-structure player landing edit, unchanged plans/actions/authority/effects, and no save/ModData text bloat.

## P7 — End-to-end developer acceptance, scale and handoff
**Status: REOPENED / IN PROGRESS.** P3B functional lifecycle coverage is green, but P3C exposed non-hermetic GUI tests and an impractically slow Xvfb-all-tests loop. Re-accept only after TEST_RUNTIME_PERFORMANCE.md passes and the split headless + focused-GUI gate is measured.

- Exercise final P0–P6 flows in headless CLI and actual Tk GUI against production Lua/Core.
- Compare startup/query/replay/output/memory budgets to P0; respect current catalog/history caps unless separately justified. Test-suite wall-clock and GUI startup are acceptance properties under TEST_RUNTIME_PERFORMANCE.md, not unbounded implementation details.
- Run final focused+broad Python suites, full Lua suite, installed Project Zomboid Kahlua compiler, deterministic CodeBuilder writer parity, save/source hash safety and git diff checks.
- Verify no new source-of-truth duplication, watched-media staging, save writes or native/runtime publication side effects.
- Prepare user native SP/MP checklist only after every developer-implementable gate passes.

**Gate:** final real-Lua + GUI/headless parity + canonical source-patch regression + performance/data-safety evidence passes, **including P3B startup/session parity and P3C hermetic/practical test-runtime acceptance**. The full headless suite runs once; focused Xvfb GUI acceptance is bounded and measured; real user persistence cannot silently affect ordinary tests. Then set **READY FOR USER LIVE TEST**.

## Closure order

1. Preserve the accepted P3B product behavior; do not revert remembered SAVE restoration, native Response Channel authority, or Explore auto-load.
2. **P3C Test Isolation & Runtime Performance** — introduce a shared hermetic GUI-test state fixture, migrate ordinary GUI tests off the real default UI-state path, separate Explore-local loading from global busy semantics, and replace broad generic waits with condition-specific helpers.
3. Define and validate the split acceptance topology: full headless suite once + focused Xvfb GUI/lifecycle modules, with measured startup and wall-clock budgets.
4. **P7 re-acceptance** — run the split Python gates, full native Lua suite, Kahlua verification, CodeBuilder/dialogue-content idempotence, data-safety checks and `git diff --check`.
5. Only after those developer gates pass may the goal return to **READY FOR USER LIVE TEST**.

## Continue / stop rule

After an accepted slice, update PROGRESS.md as concise current truth and continue automatically to the next mandatory closure slice. Do not append a historical diary and do not ask for a new /goal at phase boundaries. Stop only when the full developer objective is accepted, a genuine safety/authorization blocker prevents further work, or all implementable work is complete and only the user-owned native SP/MP gate remains.
