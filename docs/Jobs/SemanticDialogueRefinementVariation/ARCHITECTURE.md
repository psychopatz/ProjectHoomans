# Architecture — Semantic Dialogue Refinement & Variation Expansion

## Ownership

### Canonical phrase authoring

Author only in canonical conversation shards under:

`tools/semantic_harness/codebuilder/sources/conversation/`

The phrase-family layer owns alternate wording.

### Generated artifacts

Generated Lua and translations remain derived outputs.

Do not hand-edit them.

### Semantic authority

ResponseCatalog / semantic flow / policy still own:

- semantic meaning;
- conditions;
- priority;
- actions;
- gameplay effects;
- relationship authority.

Phrase expansion may not change those contracts.

### Speech realization

Speech/style realization owns:

- style selection;
- phrase-family selection;
- deterministic anti-repeat behavior.

This job may expand phrase pools and refine wording, but should not invent a parallel selector.

## Minimum-10 contract

For each canonical in-scope NPC `phraseFamily` and each active style key inside that family:

`10 <= phrase_count <= MAX_PHRASES_PER_STYLE`

Recommended new bounded cap:

`MAX_PHRASES_PER_STYLE = 16`

The minimum applies **per active style bucket**, not merely 10 total lines spread across all styles.

Reason: the runtime selects one style first. If a warm style has only one phrase while neutral has ten, warm NPCs remain repetitive.

## What counts as a meaningful variant

Two variants count as distinct only when they differ materially in spoken realization.

Good variation may change:

- clause order;
- sentence rhythm;
- directness;
- idiomatic wording;
- degree of terseness/warmth/guardedness;
- conversational framing;
- survival-world phrasing where supported.

Bad variation:

- punctuation only;
- capitalization only;
- one adjective swapped;
- contraction vs non-contraction only;
- mechanically prefixed “Well,” / “Yeah,” ten times;
- same sentence with interchangeable filler;
- semantic facts added/removed.

## Semantic invariance

Within one phrase family/style:

- same semantic meaning;
- same action/effect authority;
- same grounded fact assumptions;
- same relationship prerequisites;
- same subject/possessor perspective;
- same placeholder contract.

Variation is prose, not logic.

## Style invariance

Style buckets should remain recognizably different.

### neutral

- straightforward;
- conversational;
- not excessively warm or hostile.

### warm

- supportive/familiar where semantic context permits;
- not automatically romantic;
- no “love/sweetheart/family” unless the semantic/bond context guarantees it.

### terse

- concise;
- not broken fragments unless natural;
- not robotic labels.

### guarded

- cautious, reserved, suspicious or bounded;
- not automatically aggressive/hostile.

### bond_* styles

May reflect stronger relationship context only when the runtime's bond-style contract guarantees it.

## Persona/context principle

Personality changes **delivery**, not semantic truth.

Examples:

- high aggression may sound sharper;
- reserved style may use fewer words;
- supportive/warm style may acknowledge concern;
- fearful/shaken context may sound strained.

But a phrase must not name a trait directly unless natural and intended.

## Post-apocalyptic tone

Desired tone:

- grounded;
- practical;
- human;
- concise when danger/stress warrants;
- survival-aware when context supports it;
- occasional rough language when personality/emotion supports it.

Avoid:

- corporate/customer-service language;
- assistant/therapy-speak;
- fantasy quest-giver prose;
- constant melodrama;
- forced profanity;
- generic “apocalypse” references without context.

## EN/TL parity

Every phrase record must maintain valid language coverage according to repository translation conventions.

For EN/TL-supported families:

- preserve placeholder parity;
- use natural TL rather than copying English by default;
- shared names/tokens may remain shared;
- semantic strength and relationship meaning must match;
- do not translate literally when natural Tagalog differs.

## Phrase IDs

Stable phrase IDs are preferred for authored variation when schema/compiler supports them.

If current shard compiler derives IDs, preserve deterministic generation and source lineage.

Do not create unstable phrase identity from list position if existing mechanisms provide stronger IDs.

## Corpus inventory service

Add/extend a machine-readable dialogue variation audit that reports:

- shard;
- semantic template ID;
- style;
- phrase count;
- unique normalized EN count;
- unique normalized TL count;
- duplicate/near-duplicate candidates;
- placeholder parity;
- mixed-language suspicion;
- current Quality Sweep observation count;
- source owner;
- classification: EXPAND / EXEMPT / DEFERRED.

This audit should be usable by both CLI/agent and tests.

## Quality Sweep refinement loop

For each migration wave:

~~~text
Quality Sweep baseline
      |
      v
weak / repetitive / awkward lines
      |
      v
canonical phrase-family source
      |
      v
rewrite + expand to >=10
      |
      v
CodeBuilder regenerate
      |
      v
real Lua targeted replay
      |
      v
Quality Sweep comparison
      |
      v
accept / refine again
~~~

## Variation reachability

Having 10 phrases in JSON is not enough.

Acceptance should prove the runtime can select all 10 under deterministic salt/history exploration for representative families.

Track:

- phrase IDs observed;
- pool size;
- anti-repeat reason;
- duplicates rendered;
- unreachable phrase entries.

## Performance

Raising from <=6 to <=16 increases registry size.

Measure:

- CodeBuilder compile time;
- generated artifact size;
- Lua worker startup;
- phrase registry size;
- sentence generation throughput;
- phrase-selection overhead.

Do not optimize prematurely, but preserve bounded limits and shard structure.

## Safety

- no save ModData phrase history;
- no per-frame parsing;
- no runtime network;
- no source-save mutation;
- no semantic authority changes hidden in prose work.
