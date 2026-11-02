# Audit — Semantic Dialogue Refinement & Variation Expansion

## Audited repository state

Planning baseline:

- ProjectHoomans HEAD: `b3836b2ce35fb1161e92cf0bdb041f81e5016ae9`
- branch: existing `main`
- worktree: clean at audit start
- origin/main: `5af171b0`
- local main contains unpublished commits ahead of origin; preserve them.

No production content was modified during this planning audit.

## Quality Sweep dependency status

The prior Semantic Exhaustive Dialogue Quality Sweep now records parent completion at the current HEAD and provides the workflow needed for this job:

- sentence-first generated dialogue review;
- trigger/context evidence;
- selected semantic/template/variant/phrase identities;
- variant-frontier expansion;
- quality flags and run-level repetition analysis;
- real-Lua replay.

The new job should **use** those capabilities rather than reopen their architecture.

## Canonical content authority

Conversation authoring is sharded under:

`tools/semantic_harness/codebuilder/sources/conversation/`

Important content shards include:

- `content/greeting.json`
- `content/wellbeing.json`
- `content/health.json`
- `content/needs.json`
- `content/conversation.json`
- `content/social/tool_replies/`
- `content/social/interaction/`
- `content/command/`
- `content/task/`
- `content/event/`
- `content/combat*/`

Generated Lua under:

`Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/Semantics/Generated/Conversation/`

is derived output and must not become the authoring target.

## Existing phrase-layer design

The canonical dialogue content system correctly separates:

- semantic variant — why/when a response is appropriate;
- phrase variant — alternate wording with the same meaning.

This is the correct seam for the requested variation work.

Phrase selection occurs after semantic selection/style selection and already supports deterministic anti-repeat observability.

## Current hard limit blocks the goal

`tools/semantic_harness/codebuilder/dialogue_content.py` currently defines:

`MAX_PHRASES_PER_STYLE = 6`

The new user requirement is **minimum 10** variants for each active in-scope phrase style.

Therefore the bounded cap must be deliberately raised. The pre-existing design documentation already contemplated a conservative cap around 16 per style/family.

Recommended target:

`MAX_PHRASES_PER_STYLE = 16`

This preserves a bounded registry while allowing the requested minimum of 10 plus future headroom.

## Corpus variation baseline

A repository-wide canonical phrase-family audit found:

- **729 active style-family combinations**
- **729 / 729 currently below 10 phrases**
- **660** have only **1** phrase
- **19** have 2
- **29** have 3
- **4** have 5
- **17** have 6
- **0** currently meet the new >=10 requirement

This is a true corpus-scale content migration, not a small edit.

## Concrete quality examples

### Greeting

Some mature greeting styles currently have 6 alternatives, for example:

`semantic.flow.greeting.opening.default / neutral`

but other wording is still questionable or context-sensitive.

Examples currently visible in canonical greeting content include lines such as:

- “Morning, sweetheart.”
- “Hey, love.”
- “Back already?”
- “Good to see you. Come here.”

These require contextual scrutiny so intimacy, relationship assumptions, and situation fit are not introduced merely for variety.

### Wellbeing

Many high-frequency wellbeing families have only one phrase per style:

`semantic.question.wellbeing.default`

- guarded: 1
- neutral: 1
- terse: 1
- warm: 1

Needs-specific variants such as hunger/thirst/fatigue/panic/stress are frequently 1 phrase total.

This is exactly the repetitive/bland surface the new Quality Sweep is now capable of exposing.

### Identity / tool replies

Ask-name families are also mostly single-phrase records.

That makes repeated interaction noticeably canned and creates a high-value early migration target.

## Translation quality issue

The canonical corpus includes many TL values that are still English text.

Examples are visible in current greeting/tool-reply content.

The new refinement goal must not multiply English placeholders tenfold.

EN/TL expansion must distinguish:

- natural English;
- natural Tagalog;
- intentional shared tokens/names;
- explicit fallback where unavoidable.

Mixed-language/fake-localization bleed is a quality defect.

## Main design risk: quota-driven garbage

A numeric target can produce bad content if an agent creates:

- punctuation-only variants;
- trivial synonym swaps;
- near-duplicates;
- 10 lines with identical cadence;
- context claims not supported by semantic state;
- relationship terms that overstep bond state;
- repetitive profanity;
- overly dramatic apocalypse clichés.

Therefore “10 variants” is only accepted when they are **meaningfully distinct phrase realizations** preserving the same semantic contract.

## Main design risk: context leakage

Phrase variants may not invent:

- family/romantic bond;
- player/NPC identity knowledge;
- injuries;
- location facts;
- scarcity facts;
- hostile/friendly relationship state;
- plans/actions;
- world events.

Unless those facts are guaranteed by the semantic family/context itself.

The Quality Sweep evidence must be used to detect this.

## Recommended implementation strategy

Do not expand all 729 style buckets blindly in one giant edit.

Use corpus-wide inventory + domain waves:

1. raise phrase capacity and add machine-readable variation audit;
2. refine high-frequency Quality Sweep surfaces first;
3. expand social/tool/command/task dialogue;
4. expand event/combat/quest/knowledge dialogue;
5. reconcile compatibility/atomic/exempt categories;
6. run full corpus min-10 audit;
7. real-Lua phrase reachability/quality regression.

The parent goal remains corpus-wide even though implementation is phased.
