# Semantic Dialogue Refinement & Variation Expansion — current progress

**Parent goal status: IN PROGRESS.**

## Planning baseline

- ProjectHoomans HEAD at job creation: `b3836b2ce35fb1161e92cf0bdb041f81e5016ae9`.
- Existing Quality Sweep parent goal is recorded complete and is an accepted dependency.
- Worktree was clean at planning start.
- No production content was changed during P0 planning.

## Corpus baseline

Canonical conversation phrase audit:

- active style-family combinations: **729**
- below 10 phrases: **729**
- exactly 1 phrase: **660**
- exactly 2 phrases: **19**
- exactly 3 phrases: **29**
- exactly 5 phrases: **4**
- exactly 6 phrases: **17**
- already >=10: **0**

Current compiler bound:

`MAX_PHRASES_PER_STYLE = 6`

This must be raised before the corpus can satisfy the requested minimum.

## Phase state

| Phase | State |
| --- | --- |
| P0 — audit / contract | **COMPLETE (planning)** |
| P1 — capacity + inventory tooling | **NOT STARTED** |
| P2 — core conversation | **NOT STARTED** |
| P3 — social | **NOT STARTED** |
| P4 — commands/tasks | **NOT STARTED** |
| P5 — events/combat | **NOT STARTED** |
| P6 — remaining corpus / exemptions | **NOT STARTED** |
| P7 — corpus-wide acceptance | **NOT STARTED** |

## Immediate Next Chunk — P1A/P1B

Start with infrastructure and a truthful inventory before writing thousands of phrases.

1. raise the bounded phrase cap from 6 to 16 unless benchmark evidence establishes another safe >=10 bound;
2. update compiler/unit tests for the new bound;
3. implement the machine-readable corpus variation auditor;
4. report every phrase family/style with:
   - source shard;
   - semanticTemplateID;
   - style;
   - phrase count;
   - normalized unique EN/TL counts;
   - placeholder parity;
   - duplicate/near-duplicate suspicion;
   - source owner;
   - classification;
5. create the initial classification ledger for all 729 current style buckets;
6. prove unchanged existing content compiles/regenerates identically under the higher bound;
7. record exact results here;
8. continue automatically into P2 core conversation refinement.

## First content wave after P1

Prioritize high-frequency Quality Sweep surfaces:

- greeting/farewell;
- wellbeing;
- health/needs;
- What's Up/general conversation;
- identity/ask-name.

These currently contain many one-phrase style buckets and therefore produce obvious repetition.

## Mandatory quality principle

Do not turn:

`1 mediocre sentence → 10 mediocre synonyms`.

The goal is:

`1 weak/repetitive family → 10+ natural, distinct, context-safe realizations`.

## Completion condition

Final corpus audit must report:

`EXPAND_TO_10 buckets below 10 = 0`

plus all quality, translation, reachability, semantic-invariance and regression gates in HARNESS_ACCEPTANCE.md.
