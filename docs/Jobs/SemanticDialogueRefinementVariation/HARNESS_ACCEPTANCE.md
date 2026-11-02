# Acceptance — Semantic Dialogue Refinement & Variation Expansion

## A. Baseline and ownership

- Record exact ProjectHoomans/Core revisions.
- Quality Sweep remains an accepted dependency and continues to pass its regressions.
- Canonical conversation shards under `tools/semantic_harness/codebuilder/sources/conversation/` remain the authoring source.
- Generated Lua/translation artifacts are never hand-edited.
- Semantic ResponseCatalog conditions, actions, priorities and effects are not changed merely to improve wording.

## B. Phrase-capacity contract

- Raise the phrase-layer bound from the current 6 to a measured bounded value that supports the requirement.
- Target bound is 16 unless measured evidence requires a different bounded value.
- Compiler rejects values above the bound.
- Existing <=6 families remain behavior-compatible before content expansion.
- Generated registry and worker startup remain within measured acceptable bounds.

## C. Corpus inventory

Produce a machine-readable inventory of every canonical NPC phrase family/style containing at least:

- source shard;
- semantic template ID;
- style;
- phrase count;
- EN normalized uniqueness;
- TL normalized uniqueness;
- placeholder signatures;
- source owner;
- classification;
- Quality Sweep observation/reachability metadata when available.

The inventory must reconcile to the canonical corpus and identify all under-10 active style buckets.

## D. Classification

Every discovered phrase style receives one explicit classification:

- `EXPAND_TO_10`
- `ATOMIC_EXEMPT`
- `STRUCTURAL_NOT_PHRASE`
- `THIRD_PARTY_COMPAT_DEFERRED`
- `PLAYER_UI_OUT_OF_SCOPE`

No silent omission.

Exemptions must include a reason and be reviewable.

## E. Minimum variation

For every `EXPAND_TO_10` style bucket:

- at least 10 phrases;
- no more than configured bounded cap;
- at least 10 unique normalized EN realizations;
- at least 10 unique normalized TL realizations where TL is supported;
- no placeholder-parity mismatch;
- no exact duplicates.

Near-duplicate checks must catch trivial quota padding such as punctuation/capitalization-only differences.

## F. Semantic invariance

For each migrated family, real-worker before/after evidence must prove unchanged:

- semantic template/variant identity;
- planned/reached route;
- action/command meaning;
- authority/eligibility;
- effect delta;
- grounded fact contract;
- speaker/listener/subject perspective.

Only phrase identity/rendered wording may vary.

## G. Phrase reachability

For representative families in every migration wave:

- runtime reports phrase-pool size >=10;
- deterministic salt/history exploration selects at least 10 distinct phrase IDs;
- no phrase is permanently dead due solely to selection bug;
- immediate repetition is avoided when alternatives exist;
- anti-repeat metadata remains observable.

Corpus-wide static count alone does not satisfy this gate.

## H. Dialogue quality

Quality Sweep must be used before and after each wave.

Reject or revise new phrases that introduce:

- one-word semantic labels;
- robotic/corporate/assistant phrasing;
- unsupported family/romantic terms;
- wrong perspective;
- fake knowledge;
- generic acknowledgement overuse;
- awkward fragments;
- repetitive near-duplicates;
- inappropriate melodrama/profanity;
- mixed-language leakage.

The goal is not accepted merely because counts reach 10.

## I. Style distinctness

For multi-style families:

- neutral remains neutral;
- warm is warmer without automatically becoming romantic;
- guarded remains cautious without automatically becoming hostile;
- terse remains concise without becoming broken/robotic;
- bond styles use relationship assumptions only where their contract guarantees them.

Tests/review bundles should compare representative style outputs side-by-side.

## J. EN/TL quality

For every migrated in-scope family:

- EN/TL placeholder signatures match;
- translation keys compile normally;
- TL text is not silently populated by copying English unless the phrase is intentionally language-neutral;
- mixed-language/fallback cases are reported;
- real worker renders both languages.

A dedicated audit must report suspicious English-identical TL entries introduced or preserved in migrated families.

## K. Domain migration waves

Each mandatory wave is accepted only when its in-scope style buckets satisfy the minimum-10 and quality gates.

Required waves:

1. **Core conversation**
   - greeting/farewell
   - wellbeing
   - What's Up/general conversation
   - health/needs
   - identity/first contact

2. **Social**
   - tool replies
   - reactions/emotes
   - apology/compliment/comfort/praise/insult/hostile/romantic families
   - social interaction/director-facing spoken content

3. **Commands/tasks**
   - companion orders
   - queued/rejected/completed task replies
   - lifecycle acknowledgements

4. **Events/combat**
   - combat banter
   - kill/horde/assault reactions
   - medical/world-event reactions

5. **Quest/knowledge/navigation and remaining eligible canonical NPC speech**

6. **Compatibility/exemption reconciliation**
   - explicitly expand or classify every remaining style bucket.

## L. Quality Sweep regression

For each wave:

- generate affected sentence coverage;
- compare unique phrase IDs before/after;
- inspect flagged rows;
- inspect duplicates/repetition;
- confirm no increased invalid-surface/fallback rate;
- targeted replay of changed families passes.

## M. CodeBuilder / artifact integrity

- canonical source compiles deterministically;
- regeneration is idempotent;
- generated artifacts reflect canonical phrase count;
- translation manifests remain valid;
- Kahlua verification passes for generated Lua;
- no giant monolithic source is introduced;
- shard-size limits remain respected or are intentionally re-sharded.

## N. Performance

Measure at least before/after:

- canonical source size;
- generated phrase registry size;
- CodeBuilder compile time;
- Lua worker startup;
- sentence-generation throughput;
- phrase selection overhead;
- artifact size.

A 10+ variation corpus must remain bounded and practical.

## O. Final corpus audit

Before completion, produce a final summary:

- total phrase style buckets;
- EXPAND_TO_10 count;
- exempt/deferred/out-of-scope counts;
- minimum/median/maximum phrase count;
- number below 10 among EXPAND_TO_10 — must be **0**;
- duplicate/near-duplicate findings;
- EN/TL parity failures — must be **0** for accepted migrated content;
- Quality Sweep flagged regressions;
- real-worker phrase reachability evidence.

## P. Regression closeout

Before developer-side completion:

- new variation-audit tests pass;
- CodeBuilder/content tests pass;
- Quality Sweep tests pass;
- Response Observatory relevant tests pass;
- production Lua semantic regression passes;
- generated Lua Kahlua verification passes;
- translation verification passes;
- `git diff --check` passes;
- unrelated user work remains preserved.

Native Project Zomboid remains user-owned unless separately requested.
