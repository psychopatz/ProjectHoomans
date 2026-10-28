# Harness Acceptance — Coherent Emergent Conversation

The Semantic Lab / production Lua worker is the primary developer acceptance surface.

## Required trace chain

For human input expose a bounded chain:

1. raw text;
2. normalized text;
3. alternate recovered surfaces and recovery provenance;
4. semantic candidates;
5. candidate confidence/eligibility;
6. discourse-context evidence and adjustments;
7. selected DiscourseFrame or explicit ambiguity;
8. pragmatic frame;
9. dynamic player-affordance candidates with origin/stance/strategy;
10. selected semantic-click frame and player UtterancePlan when applicable;
11. beat/behavior candidates and selected InteractionPlan;
12. NPC/player UtterancePlan and realization components when composition is used;
13. Dialogue Content / emote / gameplay projection or authored fallback;
14. final presentation;
15. authoritative relationship/gameplay result;
16. durable conduct-memory result.

NPC semantic acts begin at the semantic-stimulus step and must show that no human NLU reparse occurred.

## Contextual evidence follow-on

The ungrounded-apology/contextual-memory follow-on is now owned by `docs/Jobs/UnifiedSemanticEvidenceArchitecture/`; its acceptance criteria are defined there and are not yet implementation acceptance. Do not execute a second acceptance matrix from this job.

## C0 regression corpus

At minimum cover these classes.

### Compact / no-space

- `fuckyou`;
- `shutthefuckup`;
- `youidiot`;
- `youreuseless`;
- `illkillyou`.

### Elongation / typo

- `fuck youuuu`;
- existing typoed-hostility regressions;
- benign elongated greetings.

### Directedness and profanity context

- `fuck you` → recipient hostility;
- `this fucking rain` → world complaint, not recipient hostility;
- `I'm fucking starving` → self-state/intensifier, not recipient hostility.

### Threat / hostile wish

- `I'll kill you` → threat;
- `I hope you die` → hostile/malicious directed act but not falsely promoted to an explicit actor threat unless the semantic evidence supports it.

### Negation

- `you're not bad` must not become a negative insult merely from the word `bad`;
- add equivalent positive/negative controls.

### Context-dependent replies

Use multi-turn cases such as:

```text
NPC: Do you trust me?
PLAYER: not really
```

and prove the final meaning includes the prior question/topic rather than only a standalone `DISAGREE`.

Also cover apology after hostility, topic continuation, interruption and valid resumption.

### Safety controls

Malformed/fuzzy text must not silently authorize:

- item transfer;
- inventory mutation;
- movement/task command;
- recruitment/relationship mutation;
- other gameplay side effects.

## Surface-recovery acceptance

Recovery must prove:

- exact path still wins;
- compact aliases are derived from registered vocabulary;
- recovery is bounded;
- ambiguity is retained;
- recovered text/provenance is visible;
- no unrestricted substring matching;
- benign single tokens do not become hostile/commands merely because they contain a semantic substring.

## Contextual resolver acceptance

For each contextual case show:

- candidate set before context;
- relevant bounded context used;
- score/eligibility change or composition reason;
- selected DiscourseFrame;
- no raw-text reparsing in ProjectHoomans.

Context may disambiguate conversation meaning but must not invent unknown facts.

## Risk-aware policy acceptance

Prove both directions:

- a valid medium-confidence conversational/social act can proceed when context supports it;
- an equally fuzzy/uncertain mutating action still clarifies or requires confirmation.

The known `HOSTILE_REMARK` around 0.83 → generic clarification failure must be eliminated without globally lowering action safety.

## Storage/context-health acceptance

CodeBuilder and Semantic Lab tooling must prove the catalog can scale without creating context-heavy monoliths.

Required evidence:

- canonical source records remain bounded and semantically named;
- generated Conversation output is split by semantic family/subdomain;
- no numeric overflow shards such as `Part02`, `Part03`, etc.;
- no opaque new generated shard names whose domain/purpose cannot be inferred from path/name;
- generated indexes contain routing/identity metadata rather than duplicate full definitions;
- root manifest stays configuration/source-root oriented rather than enumerating every semantic object;
- lightweight agent/tool indexes resolve ID → canonical source → generated shard → bounded related/dependent IDs;
- context-health report exposes largest source, largest generated shard, definitions per shard, oversized indexes, orphan/collision/reference failures and forbidden names;
- configured preferred/hard budgets are enforced;
- runtime combinations/UtterancePlans/generated buttons do not become persisted catalog records or ModData;
- targeted affected-closure compilation, if implemented, produces the same final result as a full deterministic build;
- two consecutive full generations are byte-identical.

Migration acceptance must remove current numeric/opaque generated patterns such as `SocialPart02.lua`, `CommandPart02.lua`, `QuestionPart02.lua`, `Massive.lua` and `Sgd.lua` from the Conversation output without changing semantic behavior.

## Dynamic button acceptance

Internal candidate existence is not acceptance. After representative NPC turns, inspect the same production suggestion pipeline and prove:

- authored/static choices remain available when intentionally authored;
- eligible positive-leading continuations can be generated from semantic/discourse state;
- eligible negative-leading continuations can be generated from semantic/discourse state;
- contextual/neutral/trait-induced continuations appear only from grounded player/context providers;
- trait-driven choices do not leak hidden NPC traits or private facts;
- candidates expose origin, stance, strategy, source evidence and eligibility;
- deterministic ranking/deduplication prevents near-duplicate button spam;
- the UI need not force one choice from every lane when a lane has no valid candidate;
- current-turn DIRECT_RESPONSE candidates become the selected semantic group unless explicit user navigation owns the surface;
- the same rows appear through `groups/currentGroupID` → native `session.choices` → TalkParity `conversationPresentation.responseChannel.rows`;
- the root landing group remains reachable through typed Back/navigation rather than hiding current-turn responses;
- clicking a generated choice sends its typed semantic frame directly and does not pass its displayed utterance back through NLU;
- a typed utterance with equivalent meaning and the generated button converge on the same DiscourseFrame / authoritative outcome.

At least one multi-turn hostility case should naturally offer contrasting continuations such as de-escalate/apologize, challenge/retaliate and dismiss/change-topic when context permits them.

## Compositional realization acceptance

Prove runtime construction through the existing SpeechRealization authority.

Required evidence:

- the selected semantic behavior/strategy is stable before realization;
- canonical lexical concepts come from semantic/discourse evidence rather than arbitrary raw-text echo;
- locale-specific construction is compiler-owned and deterministic;
- a bounded UtterancePlan is observable;
- the same semantic strategy can realize more than one context/style-appropriate sentence without adding one full response definition per combination;
- unsupported/ambiguous construction falls back to ordinary Dialogue Content;
- optional PBrainZ realization, if present, consumes the same plan and cannot change facts/intent/authority.

Required example class:

`fuckyouuu!!!` (or equivalent recovered insult) → canonical directed-insult payload → NPC `RETALIATE_VERBALLY / MIRROR` → a runtime-composed retort such as `Fuck you too.`, with no dedicated full-sentence definition required and no raw-input injection.

Also test non-mirroring strategies so dynamic realization is not merely an insult special case: agreement, disagreement, acknowledgement, apology/de-escalation, ask-back/follow-up and deflection.

## Social-memory saturation acceptance

Test both bounded relationship memory and conduct evidence. At minimum reproduce the exact saved Dana case when the local save is available.

Prove:

- the hostile/social act is still understood;
- a reaction can still be selected;
- relationship effect reports applied/clamped/none independently;
- relationship memory reports persisted/coalesced/pruned/dropped independently;
- conduct evidence reports persisted/coalesced/pruned/dropped independently;
- neither relationship-memory nor conduct-evidence capacity alone rejects the immediate social interaction;
- no unbounded memory/evidence growth occurs;
- no player-facing `I couldn't apply that social reaction` merely because bounded durable storage is full.

## Multi-system coherence acceptance

Protect the already-accepted interaction foundation:

- argument → apology → reconciliation;
- first-contact context;
- flows and Interaction Director coexist;
- world/grounded events may affect conversation;
- NPC-to-NPC semantics bypass text NLU;
- speech/emote/flavor share the semantic decision.

## Performance and persistence

Measure and bound:

- recovery candidates;
- parser candidates;
- discourse candidates/context rows;
- predicate rows;
- trace bytes;
- active scene/turn limits;
- durable evidence writes.

No full transcript persistence and no all-NPC/all-definition per-tick scanning.

## Final C11 gate

Developer acceptance requires:

- focused and broad real-worker corpus green;
- action-safety controls green;
- contextual multi-turn cases green;
- storage/context-health budgets, semantic shard naming and lightweight indexes green;
- dynamic authored/positive/negative/contextual button cases green;
- typed/button semantic parity green;
- compositional player/NPC UtterancePlan realization green with authored fallback coverage;
- social-memory saturation green;
- accepted NPC-scene/interaction regressions green;
- deterministic generation where relevant;
- no source-save mutation;
- no transcript/ModData bloat;
- `git diff --check` clean.

Native Project Zomboid SP/MP remains user-owned unless explicitly reassigned.
