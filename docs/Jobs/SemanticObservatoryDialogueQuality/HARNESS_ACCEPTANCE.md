# Semantic Observatory — harness and safety acceptance gates

**No phase is accepted on static schema or JSON-only checks.** This checklist uses the existing production Core+Hoomans Lua worker; Project Zomboid native SP/MP is a separate user-only final acceptance gate.

## Required evidence per relevant phase

| Gate | Real assertion |
| --- | --- |
| A. Registry correctness | New bounded pool detail equals registered Lua Catalog.POOLS entries (IDs/variants/conditions/priority/plan/template), handles unknown pool and cap, no source loading or gameplay mutation from query. |
| B. Source mapping | Authored Lua pool points to verified file or UNKNOWN; generated pool points to real reviewed CodeBuilder source and actual translation manifest or UNKNOWN. Source path cannot be invented by grep. |
| C. Selector parity | Same context, salt, history and registry selects same variant with/without diagnostics; explain lists rule-by-rule ineligibility, score, tie/hash, repeat-avoidance and final selection. Explain cannot consume the next variant. |
| D. Grounded behavior | Real Lua worker scenario includes greeting (rain/friendly/default), wellbeing/health known vs unknown, farewell with close, companion Follow/Wait and refusal, unknown-name privacy, action/no-action cases, and Leave Group for both unowned rejection **and a production-rehydrated player-owned faction warning→confirm→departure path**. Verify chosen variant/visible text plus actual authority outcome, not just plan ID. |
| E. Effects and persistence | Preview and read-only inspection create zero durable facts/commands/saves. Legitimate actions retain single authoritative execution, no extra relationship/Knowledge/ModData delta and no double transport; sourceKind SAVE remains read-only. |
| F. Languages and variants | EN/TL both resolve actual catalogs. Placeholders and formatting preserved; no fallback leak, fabricated job/identity/world facts, duplicated equivalent text or mixed-language bleed. Verify negative and ambiguous cases. |
| G. Studio/CLI parity | UI and CLI retrieve identical catalog revisions/variant IDs, actual response and outcome; GUI tests exercise real widgets/worker, headless is enough for agent mode but GUI is not considered accepted by synthetic-only tests. |
| H. Safe proposal | Before/after candidate in isolated worker differs in expected rendered response (both EN/TL), uses proper source owner, has reviewable diff and cannot alter response plan/authority accidentally; rejected proposal leaves working source unchanged. |
| I. Scale | Compare measured worker startup, catalog payload/query latency, bounded JSON output, matrix throughput/memory vs P0 baseline; paging/truncation flagged, no per-NPC tick scans or persistent debug history. |
| J. End-to-end | Focused and relevant broad Python tests, production Lua smoke, Kahlua syntax, CodeBuilder deterministic artifacts, Git cleanliness of unrelated paths, log of actual PASS/FAIL/SKIP and clear user-owned live gate. |
| K. Surface ownership / no redundancy | Simulation is the only GUI conversation/context/regression execution workbench; Studio contains Explore + Dialogue Content + Review without a second Test Lab/Coverage runner; structural authoring is Developer Tools; World Browser and Log retain sole browser/timeline roles. Moved functionality uses existing services and real-worker GUI tests pass. |
| L. Dialogue content / phrase variation | A reviewed canonical content source compiles deterministic phrase families without changing semantic selection. Phrase variants are selected after style, avoid immediate repeat, remain separately observable, and compile to ordinary string-valued EN/TL translation keys. Studio edits one migrated NPC family plus one verified player landing/choice text while structural metadata remains locked; real Lua proves unchanged plans/actions/authority/effects. |
| M. Startup/session parity | Fresh GUI startup renders zero native Response Channel rows until production conversation open; visible rows then exactly match `conversationPresentation.responseChannel`. The last active valid SAVE/player/NPC auto-restores across app recreation using existing read-only import; invalid remembered targets fall back safely; `--reset-ui-state` disables restoration. Studio Explore auto-populates a bounded first catalog page on worker-ready. |
| N. Test isolation / runtime performance | Ordinary GUI tests use isolated temporary UI state and cannot inherit the user's real active SAVE/session. Explore auto-load does not extend global Simulation busy state. Full Python regression runs once headlessly; Xvfb runs a bounded GUI/lifecycle set rather than rediscovering the entire suite. Fixture/SAVE startup and focused GUI wall-clock are measured against a practical local budget. |

## Minimum reusable scenario matrix

- Conversation: greeting opening + two turns; rainy vs clear, friendly vs guarded, resumed flow, goodbye/farewell close.
- NPC truth: healthy/unknown/injured, needs urgency, different social style and relationship attitude, identity-known vs hidden, unfamiliar stranger; no fabricated state.
- Semantics/actions: typed player request, NPC reply/suggestion, valid companion follow, mutually exclusive wait, invalid/stale/unauthorized action; verified authority and effect delta.
- Leave Group: unowned/other-owner rejection plus a disposable save-backed player-owned faction that reaches the real production warning, confirmation and ColonistDeparture transition; source save bytes remain unchanged.
- Language: EN and TL for each proposed variant family; placeholder/value and translation fallback reason.
- Selection: empty/missing pool, 1-variant, equal-score multiple variants, higher-priority overshadowing, repeat consecutive turns, bounded history pressure, load/restart state isolation.
- Performance: large registry within current caps and paginated queries; huge/untrusted requested detail rejected or truncated explicitly.

Test fixtures must use existing scenario conventions and source-backed PZ engine facts (through production fixture adapters) where the real engine is unavailable; mark those assertions ENGINE-FIXTURE, not native.

## Evidence categories

- **CODE:** verified source ownership/contract.
- **WORKER:** observed production Lua and active Core code, isolated runtime.
- **GUI:** observed actual Tk widget/surface against worker.
- **NATIVE:** user-run PZ SP/MP only.
- **SKIP/BLOCKED:** dependency or capability unavailable, with reason.

Historical passing tests are a starting baseline, not a pass for newly implemented gates. Explicitly report failed assertions and missing cells; a truncation marker or no produced trace cannot count as zero errors.

## GUI consolidation checks

- Simulation can run the same typed conversation, active context, EN/TL comparison/regression and selection/authority/provenance inspection that previously appeared across duplicate Studio surfaces.
- Simulation diagnostics expose the stable homes `Inspect | Graph | Compare / Regression | World | Debug`; moved matrix actions and “Why did this win?” remain worker-backed.
- Studio Explore can find registered response, interaction/flow and verified source ownership without executing a second scenario.
- Studio Dialogue Content can browse/edit a verified canonical phrase family with structural fields locked, validate paired EN/TL, preview via Simulation and hand a source diff to Review.
- Studio Review can preview a candidate and show before/after + invariant/effect evidence without becoming a general conversation runner.
- Structural authoring is available only through Developer Tools; primary Studio navigation no longer exposes Build Workflow, Block Palette, Interaction Composer or raw JSON editing as peer everyday tasks.
- World Browser remains the persisted target chooser and Simulation links to it; no second save browser is introduced.
- Log remains the full activity timeline.
- UI-state restore from older layouts does not crash, display removed duplicate panes, or lose the selected saved/fixture target; the consolidated nested selections persist under the current layout-state version.

## Dialogue content registry checks

- Translation JSON remains string-valued; no runtime translation API is changed to understand arrays.
- Semantic selection and phrase selection are separately reported: pool/semantic variant, speech style, phrase ID/pool size and anti-repeat reason.
- At least one migrated family produces 3+ EN/TL-equivalent phrases through real Lua while semantic conditions, priority, response plan, selected action/transport and effect deltas remain identical.
- Consecutive eligible turns avoid immediate phrase repetition under the documented bounded history policy; deterministic worker replay remains explainable.
- CodeBuilder generation from the canonical content source is idempotent and stale-source guards reject outdated Studio edits.
- A verified player landing/choice EN/TL text can be edited without changing candidate ID, route, hub ID, canonical concept or eligibility, and its visible label does not reroll on ordinary UI refresh.
- No phrase text/history is persisted to NPC ModData or source saves.

## Startup/session parity checks

- Fresh fixture startup: worker may expose diagnostic semantic suggestions, but the visible Response Channel has zero clickable rows until production Conversation open.
- After `Open conversation`, capture the worker's native presentation and assert GUI row IDs, labels and enabled state match exactly.
- Import a real read-only saved Player/NPC pair, restart the Lua worker, and assert source kind/source ID/NPC remain unchanged.
- Persist UI state, destroy the entire Semantic Lab app, recreate it, and assert the remembered active SAVE pair is re-imported automatically without opening World Browser manually.
- Delete/rename or otherwise invalidate a copied remembered test source and assert safe FIXTURE fallback plus an explicit warning.
- Recreate with `--reset-ui-state` and assert no remembered target is imported.
- Worker-ready automatically populates Studio Explore's first bounded production response-pool page; Search is not required for initialization.

## Test isolation / runtime performance checks

- All ordinary `SemanticHarnessApp` tests use a shared hermetic temporary UI-state fixture; only explicit persistence/restore tests opt into remembered SAVE state.
- Running tests is invariant to the user's real default Semantic Lab state, including `active_source_kind=SAVE`, last save path, player ID and NPC ID.
- No normal GUI test rehydrates the user's real save unless that real-save behavior is the explicit subject of the test.
- Explore auto-population has its own bounded loading state and does not make unrelated Simulation tests wait for global `app.busy`.
- Wait helpers target specific lifecycle conditions and do not hide regressions behind blanket 45–60 second ceilings.
- Record measured fixture startup and remembered-SAVE startup samples after isolation repair; compare to the audited ~1.9 s fixture / ~6.0 s SAVE observations rather than hardcoding those numbers as universal thresholds.
- Run the full Python suite once headlessly. Under Xvfb, run only the explicit GUI/lifecycle acceptance module set for the normal edit-test loop.
- Record focused Xvfb suite wall-clock. An exhaustive all-tests-under-Xvfb run, if retained, is optional/CI-style and has an explicit runtime budget.
- P3B functional assertions remain green after the performance/isolation changes.

## User-owned final live checklist

After developer-side acceptance: user verifies in native PZ SP (and MP as applicable) opening/greeting, EN/TL, real selected phrases, farewell/closing, contextual suggestions and Follow/Wait/camp, gameplay effects, hidden names, and no GUI/persistence/performance regression. Do not require Steam Workshop republishing to make the developer-side goal complete.
