# Semantic Observatory — stable contracts

## Ownership and non-duplication

1. **Authoritative semantics:** PsychopatzCore NLU/IR and ProjectHoomans Lua flows, dialogue policy, registered response catalog, realization, gameplay action handlers and Core-backed localization. Observatory never decides meaning or mutates gameplay authority.
2. **Authoritative source of edits:** hand-authored Lua remains authored Lua; CodeBuilder-generated artifacts must be edited through their *actual reviewed canonical inputs*, not by editing derived Lua. Translation assets follow the authoritative loader/manifest path found in the checkout. No parallel source database.
3. **Observability:** Lua worker exports sanitized bounded snapshots and decision reasons derived from the same production runtime structures/functions. Python projection/search/UI never reimplements eligibility or selection rules.
4. **User surfaces:** one shared service/contract is used by headless CLI/JSONL, persistent Lua worker and Tk Studio; no service daemon, external API server, new graphical application or screenshot-dependent agent workflow.
5. **Source and registration mapping:** stable poolID/variantID/templateID + source kind, module or source ID, actual owning path when verified, registry revision and content fingerprint; unresolved provenance is explicitly UNKNOWN. Never assert a path based on a string-search hit alone.

## Read-only query contracts (target; implement through existing worker protocol)

- CatalogSummary(kind, filter, cursor, limit): counts, IDs, owner/scope, source revision; **no whole-registry payload on worker startup**.
- PoolDetail(poolID): normalized variants, when, priority, fallback/template IDs, plan/act summary, verified origin, EN/TL coverage metadata; only bounded requested pool.
- ExplainSelection(poolID, scenario, salt, historyMode): per-candidate eligible, matched/failed fields, specificity, score, highest rank, deterministic tie/repeat reason, selected ID, rendered provenance. Must use production selector's own condition/scoring seam (shared pure trace helper or equivalent), not independent Python logic. Explain/preview does not alter real selection history or invoke gameplay actions.
- InspectTurn(case/turn): join existing Conversation Inspector and authoritative effect/delta record with pool/variant/template and source provenance, preserving privacy and side-effect separation.
- CoverageReport(scope, matrixID): tested vs untested, reached vs not reached, candidate eligible vs selected, dominated/shadowed under tested scenarios (not globally proved unreachable), repeated/equivalent wording flags, EN/TL failure and reason, source/HEAD fingerprints.
- Compare(baseline, candidate): bounded changed pools/variants, response selection and final text diffs, language/grounded-fact/authority deltas, regressions and explicit skipped cases.

The above are **proposed** signatures. Reconcile with existing worker request envelope, FlowEditor, runtime adapter and CLI flags before implementing. Keep outputs schema-versioned, paginated or bounded with truncation flags; expose details lazily. Shared-core dependencies and source hashes must be part of reproducibility metadata.

## Content improvement contract

Agent workflow: **discover → inspect → evidence-based coverage matrix → propose → isolated preview → real-Lua validation → review diff → approved source edit → regenerate only if canonical owner requires it → fresh worker replay**.

- A proposal targets verified stable source IDs and a baseline revision; reject stale fingerprints, duplicate IDs, unsupported edit targets or unapproved source-owner changes.
- Preserve all non-text metadata (when, priority, plan.turns, groundedFactRefs, translationArgs, eligibility, authority, disclosure and tool dispatch) for a *variant-only* improvement unless scope explicitly authorizes a behavior change.
- Validate EN/TL meaning, grammar, key/placeholder correspondence, contextual voice, non-repetition, unknown-information disclosures, and no invented facts about identity/world/relationships.
- Never assume a generic language model text proposal grants authoritative action execution. The worker and owning gameplay domain decide outcomes.
- Text improvements use approved source patches in the actual repository. Temporary proposals, overlays and test copies live outside watched media and outside user saves; only reviewed changes reach mod assets.
- Optional future ChatGPT orchestration uses repository access and the same CLI via authorized desktop tooling; no requirement that ChatGPT itself runs inside PZ or in the game loop.

## Scale, reliability and privacy

- Index lightweight registry metadata once per worker generation/revision, not per frame or NPC. Query detailed variants on demand. Cache by worker generation + source/content fingerprint; invalidate on restart/edit/registration or dependency revision change.
- Keep startup capabilities/handshake lean; lazy detail fetches with page limits and strict maximum byte/time budgets. The existing serialized worker request queue remains authoritative.
- Coverage runs are offline, bounded, deterministic where feasible and scenario-isolated. Reset or explicitly model bounded per-NPC response history between cases; preserve natural history within intentional conversation sequences.
- Save-backed testing is read-only and labels source (SAVE vs FIXTURE). Never write sensitive saved NPC/private knowledge into committed artifacts or return unbounded actor records.
- Measure catalog load/query, worker restart, replay throughput, memory/output size, and selection/translation regression before altering catalog caps or adding caches. No per-NPC persistent debug history and no runtime network inference.


## Dialogue content ownership

- **ResponseCatalog answers what the NPC means.** Conditions, priority, semantic variant identity, plans and gameplay-related metadata remain there.
- **SpeechRealization answers how the NPC speaks.** Existing style resolution remains authoritative.
- **Dialogue Content phrase registry answers which equivalent wording is rendered.** It runs after semantic/style choice, is deterministic/anti-repeat and cannot change actions, plans or authority.
- **PsychopatzCore Translation remains string-valued.** Phrase arrays are never stored directly as translation values; CodeBuilder emits ordinary EN/TL keys plus bounded compiled phrase-family metadata.
- **Canonical authoring is source-controlled, not ModData.** Studio edits a reviewed CodeBuilder content source with stale guards; generated Lua/translation artifacts are derived output.
- **Player navigation wording is stable by default.** Studio may edit verified landing/choice EN/TL content, but route/hub/concept/eligibility fields are locked and labels do not reroll on every UI refresh.

## Human surface ownership

The GUI follows **one job, one home**. Detailed migration and acceptance are in [SURFACE_CONSOLIDATION.md](SURFACE_CONSOLIDATION.md).

- **Simulation** is the sole GUI runtime workbench: conversation/Response Channel, fixture or save-backed context, active selection/authority/effects inspection, comparisons/regressions, dialogue graph and runtime/world/debug diagnostics. Studio must not own a second utterance runner or scenario context.
- **Studio** is the source/content/change workbench: **Explore** (registered responses/interactions/flows/sources), **Dialogue Content** (content-only EN/TL phrase families and verified player-choice wording), and **Review** (candidate before/after and approval evidence). Structural flow/source/block/interaction mutation is relegated to Developer Tools, not a primary Studio workflow.
- **World Browser** is the sole persisted save/target discovery surface. Simulation links to it and consumes the selected target; it does not recreate the browser.
- **Log** is the sole complete activity timeline. Other surfaces expose bounded local status.
- Headless CLI uses the same worker/services and remains the agent-facing parity interface. GUI consolidation must not fork or delete those contracts.

The former Studio Test Lab and Coverage functionality now reuses the single Simulation execution path. Context-specific selection explanation belongs to Simulation Inspect; Studio Explore retains static variant/source metadata. Existing Flow Graph mutation, raw Dataset editor, Block Palette, Interaction Composer and Build Workflow move behind Developer Tools, with Build Workflow retained as a legacy/retirement candidate until unique capability ownership is fully proven.
