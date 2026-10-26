# Semantic Observatory & Dialogue Quality Harness — full developer roadmap

**Parent goal: IN PROGRESS / PARTIALLY IMPLEMENTED.** These are **mandatory developer-side phases** P0–P7, not eight separate /goal assignments. A phase or Next Chunk passing is not completion of the parent goal. Preserve accepted Semantic Lab / CodeBuilder / native semantic work; audit before touching it.

## P0 — Baseline and canonical contracts

- Reinspect working main, Core paired version, active registered sources and linked jobs; map all existing response/flow/translation/suggestion ownership.
- Capture source/registry revisions; establish checked-in source versus generated artifact rules, current detail/trace gaps, production worker startup and no-write guarantees.
- Run existing focused real-worker inspector/flow/CodeBuilder/response checks and measure catalog payload, initialization, query, replay and memory baselines; record exact failures/skips.
- Define schema-versioned, bounded, source-provenance and side-effect-free query contracts that extend existing worker protocol rather than creating a second program.

**Gate:** source-to-registration-to-render chain for one greeting, one contextual question and one real registered action is evidenced; representative baseline, performance budget measurements and contract are documented; no new API duplicates existing authority.

## P1 — Read-only runtime catalog introspection

- Extend actual production Lua FlowEditor/ResponseCatalog observation to enumerate real registered pool variants, conditions, priorities, template/plan summaries, source kind and verified source provenance.
- Keep broad catalogs IDs+counts only and request detailed records lazily; pagination, stable IDs, bounded sizes, revisions and explicit UNKNOWN source ownership.
- Preserve generation/source kinds: authored Lua, canonical CodeBuilder-reviewed sources, generated artifacts and Core-backed translations. Never parse/execute arbitrary Lua in Python for semantic truth.
- Expose same service to CLI and GUI, starting with one pool-detail query.

**Gate:** selected actual loaded pool and variants exactly match production Lua; stable origin/translation metadata or explicit UNKNOWN; no writes, bounded response/worker startup, no runtime selection behavior change.

## P2 — Explainable selection and authority provenance

- Instrument or refactor the **same** Lua matching/scoring/tie/history path to produce optional read-only per-candidate evidence without modifying selection state; keep prior production outcomes.
- Join selected variant/template/plan source to current Conversation Inspector final text, translation chain, action/command result, effect/delta and NPC/flow state.
- Distinguish ineligible, lower-scoring, tied, anti-repeat rotation and unavailable; unknown context remains unknown rather than fabricated.
- Include hostile, identity-hidden, invalid/stale, weather/personality and side-effect-free previews.

**Gate:** observed actual selected variant equals explanation for seeded and natural-history worker turns; explain does not mutate last-variant history or execute actions; native-shaped authority and negative cases remain intact.

## P3 — Human Studio: observability-first

- Make Catalog, Test Lab, Coverage and Review readable primary surfaces inside **existing** Semantic Lab Tk UI. Reuse Interaction Explorer, current Flow view, worker/inspection controllers and reusable widgets.
- Support search by topic/pool/flow/condition/owner, actual variant contents, source and EN/TL keys; from a result open a focused test and trace.
- Display candidate reasons and contextual final text as human-readable summaries; raw JSON remains available as an advanced view.
- Preserve Advanced Flow graph/Build workflow/Block palette/Interaction Composer without speculative migration or deletion.

**Gate:** an operator can locate a real greeting, identify selected/overridden variants and run a corresponding Lua-backed scenario without authoring or editing JSON; UI/CLI show the same values.

## P4 — Grounded scenario matrix and quality coverage

- Define reusable, bounded matrix cases by EN/TL, personality/social style, trust/relationship, unknown name/privacy, weather/time, need/health, active flow, companion authority and negative permissions.
- Run actual Core+Hoomans worker, reset histories between unrelated cases and deliberately retain history for anti-repeat sequences.
- Produce measured outcomes: eligible/reached/selected, fallback, conditional dominance, potentially shadowed under tested contexts, repetition/equivalent meaning, translation fallback/placeholder mismatch, factual-disclosure and unintended effect deltas. Distinguish untested from unreachable.
- Store compact summarized evidence and fixture definitions, not unbounded NPC state or large duplicate transcripts.

**Gate:** existing greeting/wellbeing/farewell/companion action scenarios reproducibly report both expected and negative behavior, EN/TL; deviations are actionable with exact source/worker revision.

## P5 — Agent-first CLI/reporting

- Add stable headless commands for catalog query, pool detail, selection explain, scenario coverage, case replay and candidate/baseline comparison, routed through the same inspection/query services as GUI.
- Emit machine-readable versioned JSON/JSONL with limits, paging/cursors, truncation, fingerprints, sourceKind (FIXTURE/SAVE), exit codes and actionable errors.
- Include a concise CLI guide for ChatGPT + authorized Desktop Commander/GitHub and local Codex; never require screenshots or force agent to dump whole Lua file trees for a single response pool.
- Verify CLI/GUI parity, wrong/unknown IDs, invalid/stale revisions, worker crashes, heavy registries, missing Core and permission failures.

**Gate:** an agent can find and explain one pool, exercise EN/TL context matrix and return a bounded report using only headless commands; same registered Lua outcomes as GUI.

## P6 — Safe delegated dialogue quality / variant workflow

- Given a named response family, retrieve actual source/variants, eligibility/plan/translation contracts and measured gaps; generate *proposals* only, not implicit production policy.
- Support reviewable targeted edits to hand-authored Lua or actual CodeBuilder canonical source (never overwriting generated artifacts directly); preserve non-text metadata/side effects unless separately authorized.
- Validate candidate IDs and limits, syntax and Kahlua, EN/TL/translationArgs and placeholders, tone/semantic fidelity, fact/disclosure safety, duplicate meanings, flow/authority regression and deterministic output.
- Stage outside watched media and user saves; run real Lua worker from an isolated candidate source tree or approved bounded worker overlay. Diff fingerprint + outputs + no-write verification before integrating. Fresh worker must demonstrate changed dialogue without altered game authority.
- Human/agent may review and approve source changes under repo Git policy; do not auto-approve an LLM just because it produces grammatical text.

**Gate:** demonstrate one real greeting/response family improved in both languages, with reproducible before/after worker dialogue, observed variant distribution, bounded source diff, unchanged gameplay effects and explicit approval.

## P7 — End-to-end developer acceptance, scale and handoff

- Exercise all P0–P6 flows in both CLI and visible Tk GUI (or honestly mark UI unavailable, keep developer-side gate open), production module worker, EN/TL, registered command and refusal, saved selection read-only where safely available.
- Verify startup and latency/memory/report budgets against P0, including catalog caps (256 pools, 16 variants per pool, 256 last selections); justify any later cap change through measured tests.
- Run focused and broader relevant Python, Lua suites, Kahlua and deterministic CodeBuilder writer parity; inspect git diff, provenance, watcher safety and no new source-of-truth duplication.
- Prepare user-facing acceptance checklist for native SP/MP only after all developer-implementable work passes. No native launch or Workshop operation by agent.

**Gate:** real Lua + GUI/headless parity + source patch regression + performance and data-safety evidence; remaining native gameplay proof explicitly user-owned. Then and only then set parent status READY FOR USER LIVE TEST; after user acceptance, maintenance-ready.

## Stop / continue rule

After any accepted phase: update PROGRESS with exact evidence/HEAD and immediate next mandatory chunk, then **continue automatically**. Do not stop at a phase boundary or ask for another /goal. Stop only for the fully completed developer objective, a genuine conflict/blocker, forbidden operation, or explicit user-owned native acceptance after all implementable work. Never invent completion.
