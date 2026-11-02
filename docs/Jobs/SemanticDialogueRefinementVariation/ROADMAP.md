# Roadmap — Semantic Dialogue Refinement & Variation Expansion

## Parent completion condition

The goal is complete only when every eligible canonical NPC phrase style has at least **10 meaningful phrase variants**, the wording has been refined against the Project Hoomans dialogue style standard, EN/TL parity is valid, real Lua proves runtime phrase reachability/anti-repeat, semantic/gameplay behavior is unchanged, and the final corpus audit has zero under-10 `EXPAND_TO_10` buckets.

## P0 — Corpus audit and migration contract — COMPLETE (planning)

Planning audit established:

- current phrase cap = 6 per style;
- 729 active style-family combinations;
- all 729 are currently below 10;
- 660 currently have only one phrase;
- canonical phrase ownership is sharded CodeBuilder content;
- Quality Sweep is now suitable as the review/acceptance loop.

No dialogue content was changed during P0 planning.

---

## P1 — Capacity, audit tooling and safe baseline

### P1A — Raise bounded phrase capacity

Raise `MAX_PHRASES_PER_STYLE` to 16 unless benchmark evidence justifies a different bounded cap >=10.

Update compiler/tests and generated-runtime assumptions without changing existing content.

### P1B — Corpus variation auditor

Implement a reusable machine-readable auditor that reports:

- phrase count;
- normalized uniqueness;
- placeholder parity;
- language parity;
- duplicate/near-duplicate candidates;
- source/classification;
- under-10 status.

### P1C — Classification ledger

Classify every style bucket as EXPAND / EXEMPT / DEFERRED / OUT_OF_SCOPE with reasons.

### Gate

HARNESS_ACCEPTANCE B–D pass, existing content regeneration is behavior-identical, and Quality Sweep baseline remains green.

---

## P2 — Core conversation refinement

Migrate the highest-frequency sentence-review domains first.

### P2A — Greeting / farewell

Refine and expand all eligible greeting/farewell active styles to >=10.

Remove unsupported intimacy/context leakage discovered by Quality Sweep.

### P2B — Wellbeing / health / needs

Expand default, fatigue, hunger, thirst, panic, stress, injury and related families.

Ensure need-specific wording remains grounded and does not fabricate inventory availability.

### P2C — What's Up / conversation / identity

Expand ordinary social conversation and ask-name/identity families.

Protect identity-trust rules and placeholder contracts.

### Gate

Every P2 EXPAND_TO_10 style passes >=10 unique EN/TL phrases, real-Lua phrase reachability, semantic invariance and Quality Sweep review.

---

## P3 — Social interaction refinement

Expand/refine:

- social tool replies;
- apology;
- comfort;
- compliment/praise;
- insult/hostile;
- flirt/romantic/sexual content within existing eligibility rules;
- emote replies;
- social interaction/dialogue-director spoken content.

Special emphasis:

- warm != romantic;
- friend != family;
- guarded != hostile;
- avoid repetitive canned acknowledgements.

### Gate

All P3 eligible styles satisfy minimum-10 and relationship-safety acceptance.

---

## P4 — Commands and tasks

Expand/refine:

- companion command replies;
- queued/rejected/failed/completed acknowledgement families;
- follow/stay/camp/return-home;
- task lifecycle and tool replies.

Preserve exact action/queue/reject semantics.

### Gate

Text-only changes produce identical command authority/effect outcomes and every eligible style reaches >=10.

---

## P5 — Events and combat

Expand/refine:

- zombie/horde reactions;
- kill reactions;
- human combat banter;
- assault reactions;
- medical/world-event reactions.

Requirements:

- short enough for gameplay;
- personality-sensitive;
- no long exposition;
- no repetitive profanity;
- no invented event facts.

### Gate

Combat/event phrase pools reach >=10 where eligible and real event/worker fixtures prove semantic/context fidelity.

---

## P6 — Quest, knowledge, navigation, compatibility and remainder

### P6A — Remaining first-party spoken dialogue

Expand/refine eligible quest, knowledge, navigation and remaining canonical NPC speech.

### P6B — Compatibility reconciliation

For compatibility/third-party-oriented content, explicitly:

- expand where Project Hoomans owns safe wording; or
- classify THIRD_PARTY_COMPAT_DEFERRED with reason.

### P6C — Atomic/exemption reconciliation

Review every remaining under-10 style.

No silent leftover records.

### Gate

Corpus inventory has no unclassified style bucket.

---

## P7 — Corpus-wide quality and runtime acceptance

### P7A — Full min-10 audit

Required result:

`EXPAND_TO_10 buckets below 10 = 0`

### P7B — Runtime reachability

Use Quality Sweep/worker coverage to prove phrase pools >=10 are genuinely selectable across representative domains.

### P7C — Quality review

Run broad sentence generation and inspect:

- awkward flags;
- duplicates;
- variant collapse;
- relationship leakage;
- perspective;
- translation bleed.

Repair regressions rather than merely documenting them.

### P7D — Performance and artifact closeout

Measure registry/runtime impact and run full regression/idempotence/Kahlua/translation gates.

### Gate

All HARNESS_ACCEPTANCE requirements pass. Only then mark developer-complete.

---

## Deferred after parent completion

- new semantic intents/behaviors;
- additional languages beyond current scope;
- runtime LLM-generated dialogue;
- automatic unreviewed prose rewriting;
- native PZ automation.
