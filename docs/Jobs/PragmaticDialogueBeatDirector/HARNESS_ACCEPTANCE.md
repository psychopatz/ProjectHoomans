# Harness Acceptance — Pragmatic Dialogue Beat Director

The Semantic Lab is not optional tooling for this goal. It is the primary
developer acceptance surface for beat/director behavior.

## Authority rule

Acceptance must run through the existing real production Lua worker and the
same Core + Project Hoomans semantic modules used by the harness.

Python may present, edit, schedule, compare, or project worker evidence. It must
not implement a second beat selector or response policy.

## Required per-turn evidence

A director-enabled worker turn must expose enough bounded evidence to recover:

1. original player text/frame;
2. Core candidates and selected semantic IR;
3. active/suspended flow state before/after;
4. pragmatic interpretation/context references used;
5. every beat considered in the bounded candidate set;
6. predicate pass/fail reasons;
7. beat activeBefore/activeAfter and entry/exit reason;
8. candidate behaviors;
9. contextual modifiers actually applied;
10. selected behavior or explicit no-selection;
11. resulting ResponsePlan;
12. response-pool/content lineage;
13. translation lookup and final rendered NPC text;
14. authoritative side effects/transport, if any;
15. any harness override marker.

A selected beat without final rendered text is not end-to-end acceptance.

## Beat Studio acceptance

The existing Semantic Lab must support, inside the same application:

- list/search production beats and behaviors;
- open a canonical beat;
- clone/new draft;
- edit entry/maintain/exit predicates;
- edit candidate behaviors and bounded relevance metadata;
- edit cooldown/turn/group metadata;
- inspect normalized advanced data;
- Validate Draft through production Lua validation;
- Preview Draft against the current scenario without committing a normal turn;
- Register Draft worker-locally;
- run a real multi-turn conversation against the registered draft;
- Save/Open bounded draft files for review;
- show Draft / Worker Registered / Canonical provenance.

Registration must disappear on worker restart unless promoted through canonical
CodeBuilder source.

## Compiler/string acceptance

Beat/behavior authoring must prove the complete source→generated→worker loop.

At least one acceptance case must:

1. modify a canonical beat/behavior/content source record;
2. change first-party EN wording and one additional available locale;
3. regenerate through the existing Conversation compiler;
4. show generated translation key/bundle/runtime artifacts;
5. show no manual generated-file edit;
6. regenerate again byte-identically;
7. restart/reload the worker;
8. prove the new generated wording is selected through the intended beat and
   behavior.

Also prove a synthetic additional locale is discovered/generated without adding
a language whitelist in Python/Lua.

## Natural vs override testing

Simulation may provide:

- Natural;
- Force eligible;
- Force active;
- Disable.

Any forced/disabled result must visibly carry `HARNESS_OVERRIDE`.

Forced cases are useful for behavior isolation but **cannot** prove natural beat
entry/selection.

Every initial reference beat must have at least one natural production path.

## Required scenario families

### Baseline parity

Protect:

- recognized hostile language does not fall into generic clarification;
- truly ambiguous/low-confidence language can still clarify safely;
- existing command/quest/gift/needs/wellbeing flows remain functional.

### Argument escalation

Use multiple paraphrases/typos rather than one exact insult.

Prove:

- hostility is understood;
- argument beat naturally enters under its conditions;
- behavior choice changes with grounded personality/relationship context;
- no unauthorized gameplay mutation occurs.

### Reconciliation

After prior hostility:

- apology/repair language is interpreted;
- reconciliation can become eligible;
- NPC may accept, remain guarded, refuse, or end topic according to context;
- behavior is not scripted solely by one apology phrase.

### Suspicious first contact

Prove first-contact context can bias questioning/warning/de-escalation without
turning every unrelated utterance into identity evasion.

### Flow coexistence

At least one case must show a beat interrupting/coexisting with a flow and the
flow later resuming/retiring correctly.

## Timeline acceptance

The GUI must offer a bounded turn timeline that can show, at minimum:

- player/NPC turn;
- active flow;
- active beat;
- entered/exited beat;
- selected behavior.

Selecting a turn must expose the real worker evidence for that turn.

## Regression capture

From a successful conversation, the workbench should be able to save a bounded
regression case containing:

- scenario inputs/identity;
- turn sequence;
- expected semantic/beat/behavior constraints;
- allowed response pool(s) or semantic content IDs;
- forbidden side effects;
- natural vs override mode.

Where wording intentionally varies, do not require one exact sentence.

Headless replay must use the same production Lua worker.

## Scenario matrix

The harness must support a bounded matrix over useful context dimensions such
as:

- aggression/confidence/fear;
- relationship/trust/respect;
- safe vs dangerous situation;
- relevant active flow state.

The matrix should report beat/behavior outcomes and failures without launching
one unbounded worker per combinatorial possibility.

## Performance/bounds

Measure and cap:

- beat count;
- predicates per beat;
- behavior candidates per beat;
- active/recent beat state;
- pragmatic topic/reference state;
- trace rows/bytes;
- timeline turns;
- catalog page sizes.

No per-NPC/per-tick whole-catalog evaluation is allowed.

## Developer completion

Developer-side acceptance is complete only when P8 in `ROADMAP.md` passes.

Native Project Zomboid SP/MP validation is user-owned unless the user explicitly
reassigns it.
