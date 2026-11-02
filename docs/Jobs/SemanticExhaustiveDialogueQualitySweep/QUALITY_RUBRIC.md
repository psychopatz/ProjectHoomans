# Dialogue Quality Rubric

This rubric guides deterministic flags and LLM/human review. It is **not** gameplay authority and must not be compiled into a simplistic runtime good-dialogue score.

## 1. Semantic correctness and grounding — highest priority

A line must remain faithful to the semantic plan and known context.

Reject or strongly flag:

- claims the NPC cannot know;
- unrevealed identity/name leakage;
- family/intimacy claims with no supporting relationship/bond context;
- saying an action occurred when authority rejected or never executed it;
- answering the wrong subject;
- switching speaker/possessor perspective;
- invented locations, jobs, factions, injuries or relationships.

A stylish line that is semantically wrong is still a failure.

## 2. Perspective and agency

The NPC should speak from the NPC's viewpoint unless the semantic act intentionally quotes/reports another actor.

Review for:

- NPC describing player state as their own;
- first/second-person inversion;
- possession inversion such as my family vs your family unsupported by frame;
- issuing a command when the response plan only acknowledges;
- claiming player intent or feelings without semantic evidence.

Use actor/referent metadata where possible; pronouns alone are not sufficient proof.

## 3. Relationship and familiarity

Wording should fit actual relationship context.

Examples requiring scrutiny:

- family, brother, sis, love, darling, best friend when no bond supports it;
- warm intimacy from an unknown/hostile stranger;
- formal distance from a deeply bonded companion when the response family claims intimacy;
- romantic wording without relevant relationship/compatibility context.

Do not ban colloquial man, mate, pal, and similar address terms globally; evaluate language, personality and context.

## 4. Natural spoken English/Tagalog

Prefer complete, conversational speech appropriate to an adult survivor.

Common defects:

- meaningless one-word semantic labels such as family;
- fragments produced by missing template clauses;
- raw translation keys/placeholders;
- unnatural template concatenation;
- overly formal/corporate phrasing;
- repetitive I understand / acknowledge patterns;
- grammar broken by optional arguments.

Short speech is allowed. Yeah. or No. can be excellent when context supports it.

## 5. Character/persona fit

Personality should affect **how** a valid meaning is expressed, not replace the meaning.

Review whether:

- aggressive/brave/guarded/friendly traits change tone plausibly;
- every trait is being name-checked or caricatured;
- unrelated likes/preferences leak into conversation;
- generated personality dimensions produce distinguishable but not absurd voices;
- the same line appears across radically different persona contexts when variety is expected.

## 6. Post-apocalyptic / Project Zomboid fit

The desired voice is grounded survival conversation, not generic assistant prose.

Prefer, where context supports it:

- economical spoken phrasing;
- practical references to danger, scarcity, exhaustion, shelter, trust or survival;
- roughness or profanity appropriate to personality/emotion;
- understated reactions instead of exposition.

Penalize:

- customer-service/corporate language;
- therapy-assistant phrasing;
- fantasy/RPG quest-giver diction unless intentionally authored;
- modern social-media/internet jargon that clashes with the setting;
- melodrama in routine exchanges;
- profanity inserted into every line merely to sound apocalyptic.

Post-apocalyptic is a contextual style target, not a requirement to swear.

## 7. Specificity vs blandness

A line can be semantically correct yet poor because it says almost nothing.

Review repeated generic responses such as:

- Okay.
- I understand.
- That is good.
- I see.
- repeated acknowledgement templates across unrelated situations.

A generic acknowledgement is acceptable when the interaction is trivial. Flag it when a more specific response family exists or when overuse makes characters indistinguishable.

## 8. Repetition

Evaluate at several levels:

- exact immediate repeat;
- same phrase family repeated despite available alternatives;
- different IDs rendering identical text;
- many contexts collapsing onto one canned sentence;
- variant pools whose supposed diversity is superficial punctuation/synonym swaps.

Anti-repeat must remain deterministic and bounded.

## 9. Language parity

For EN/TL:

- same semantic meaning and authority;
- correct placeholders/arguments;
- no unintended fallback/mixed-language bleed;
- comparable relationship/persona strength;
- no line becomes a fragment only in one language.

Do not demand literal translation when natural phrasing differs.

## Suggested review labels

- CRITICAL: semantic/authority/privacy/perspective defect or nonsensical output.
- HIGH: strong relationship mismatch, broken grammar/template, severe robotic fragment.
- MEDIUM: blandness, persona mismatch, repetition, awkward setting fit.
- LOW: stylistic preference with no semantic harm.
- OK: acceptable in tested context.

LLM judgments must cite the evidence row/context that motivated them and must not silently modify gameplay metadata.
