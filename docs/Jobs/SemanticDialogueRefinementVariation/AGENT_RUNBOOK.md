# Agent runbook — Semantic Dialogue Refinement & Variation Expansion

## Operating goal

Refine Project Hoomans NPC dialogue and expand every eligible canonical phrase style to **at least 10 meaningful variants**, using the working Quality Sweep as the discovery and acceptance loop.

This is a corpus-wide content-quality migration.

The full P1–P7 roadmap is the completion boundary. A single domain or 10-phrase family finishing is not completion.

## Read order

1. root `AGENTS.md`
2. this job's `README.md`
3. `AGENT_RUNBOOK.md`
4. `ARCHITECTURE.md`
5. `STYLE_GUIDE.md`
6. `HARNESS_ACCEPTANCE.md`
7. `ROADMAP.md`
8. `AUDIT.md`
9. `PROGRESS.md` **last**

Also read relevant current authority docs only as needed:

- `docs/Jobs/SemanticExhaustiveDialogueQualitySweep/`
- `docs/Jobs/SemanticObservatoryDialogueQuality/DIALOGUE_CONTENT_REGISTRY.md`

## Checkout rules

- Work only in `/home/psychopatz/Zomboid/Workshop/ProjectHoomans`.
- Existing `main` only.
- Inspect HEAD/status/upstream/worktrees before writes.
- Preserve unpublished history and unrelated work.
- No blind pull/reset/rebase/auto-stash/force-push.
- Do not push unless explicitly authorized.
- Do not create checked-in `GOAL_PROMPT.md`.

## Canonical-source rule

Edit canonical conversation shards only.

Never hand-edit generated Lua/translation output as the source of truth.

Regenerate through existing CodeBuilder.

If ownership is uncertain, inspect source lineage before editing.

## Minimum-10 rule

For every style bucket classified `EXPAND_TO_10`:

- >=10 phrases;
- genuinely distinct;
- semantically equivalent;
- within bounded compiler cap;
- EN/TL parity;
- no exact/near-duplicate quota padding.

The minimum is per active style, not per semantic family total.

## Content-writing discipline

Use `STYLE_GUIDE.md`.

Before accepting each phrase ask:

- same semantic meaning?
- context-safe?
- correct perspective?
- natural spoken language?
- style-appropriate?
- distinct enough?
- relationship-safe?
- setting-appropriate?
- EN/TL parity?
- placeholders intact?

Do not create prose purely to hit count 10.

## Quality Sweep loop

For every migration wave:

1. generate baseline sentence evidence;
2. identify awkward/repetitive/high-frequency families;
3. trace to canonical source;
4. refine/expand canonical phrases;
5. compile/regenerate;
6. run targeted real-worker replay;
7. run affected Quality Sweep;
8. inspect actual rendered lines;
9. fix issues;
10. update PROGRESS;
11. continue automatically.

## Semantic-invariance rule

Do not change:

- response conditions;
- priorities;
- actions;
- authority;
- effect deltas;
- semantic plans;

unless a separate explicitly approved semantic bug is discovered.

If a sentence is bad because semantic routing is wrong rather than wording, document it as a blocker/follow-up instead of hiding the behavior change inside this content goal.

## Translation rule

Do not clone English into TL merely to satisfy the count.

Natural TL/Taglish should follow repository conventions.

Preserve placeholder parity exactly.

If translation quality cannot be established safely for a phrase, flag it for review rather than silently shipping poor text.

## Work batching

This is a large corpus.

Work domain-by-domain with coherent commits.

After each accepted domain:

- run focused tests;
- regenerate;
- verify idempotence;
- run targeted Quality Sweep;
- update current progress;
- commit;
- continue to the next mandatory domain.

Do not ask for approval between normal mandatory phases unless a genuine scope/authority blocker appears.

## Validation

At minimum per wave:

- canonical audit;
- CodeBuilder compile;
- relevant content/unit tests;
- targeted real Lua;
- phrase reachability;
- Quality Sweep output review;
- EN/TL checks;
- `git diff --check`.

At final closeout run full required regression set from HARNESS_ACCEPTANCE.md.

## Documentation discipline

- Keep root AGENTS.md unchanged unless repository-wide durable policy changes.
- PROGRESS is current truth, not a chronological diary.
- Do not duplicate the same narrative across every document.
- Preserve explicit exemption reasons.

## Stop conditions

Stop only when:

1. all mandatory P1–P7 gates pass; or
2. a genuine blocker prevents further safe work after independent work is exhausted; or
3. only explicitly user-owned native acceptance remains.

Do not stop because:

- one family reaches 10;
- one domain reaches 10;
- the corpus count is large;
- Quality Sweep looks better;
- a code-generation pass succeeds.

## Final report

Report:

- eligible style count;
- expanded count;
- exemption/deferred counts;
- final phrase-count distribution;
- unique EN/TL counts;
- real phrase-reachability evidence;
- Quality Sweep before/after findings;
- semantic-invariance evidence;
- performance/artifact impact;
- tests;
- commits;
- push/publication state.
