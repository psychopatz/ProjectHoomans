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
9. beat/behavior candidates and selected InteractionPlan;
10. Dialogue Content / emote / gameplay projection;
11. final presentation;
12. authoritative relationship/gameplay result;
13. durable conduct-memory result.

NPC semantic acts begin at the semantic-stimulus step and must show that no human NLU reparse occurred.

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

## Social-memory saturation acceptance

Construct a disposable saturated conduct record and prove:

- the hostile/social act is still understood;
- a reaction can still be selected;
- relationship effect reports applied/clamped/none independently;
- durable evidence reports persisted/coalesced/pruned independently;
- no unbounded evidence growth occurs;
- no player-facing `I couldn't apply that social reaction` merely because the evidence ledger is full.

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

## Final C8 gate

Developer acceptance requires:

- focused and broad real-worker corpus green;
- action-safety controls green;
- contextual multi-turn cases green;
- social-memory saturation green;
- accepted NPC-scene/interaction regressions green;
- deterministic generation where relevant;
- no source-save mutation;
- no transcript/ModData bloat;
- `git diff --check` clean.

Native Project Zomboid SP/MP remains user-owned unless explicitly reassigned.
