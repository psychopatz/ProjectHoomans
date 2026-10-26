# Event Follow-up Contract

## Product behavior

When an NPC speaks because of a grounded semantic event, that utterance may create a short-lived opportunity for the player to ask about the event.

Examples:

- horde warning → “Where are they?” / “How many?”;
- wounded NPC → “What happened?” / “Who hurt you?” / “What do you need?”;
- leader death → “Who died?” / “What happened?” / “What do we do now?”;
- abandonment complaint → “Are you hurt?” / “Who was after you?”;
- safety warning → “What is it?” / “Where?”.

The follow-up is optional and grounded. Not every ambient line needs one.

## Reuse existing lifecycle

This goal must not create a separate event-follow-up state system.

Use:

- `SemanticInteractionLifecycle.RecordNPCSpeech`;
- existing thread/beat/event refs;
- `ResponseWindow`;
- `ResponsePlan` offers;
- `DialogueContextState` pending follow-up/agenda;
- `SemanticContextResolver`;
- existing Suggestions providers/ranking;
- existing semantic typed/click input routes.

## Event response envelope

A follow-up-capable NPC event response should expose bounded metadata:

```text
eventRef
topic
responsePoolID
responsePlanID
realizationID
groundedFactRefs[]
offers[]
freshness/expiry policy
```

Use existing schemas/fields where available. Add only the minimum missing field required for interoperability.

## Eligibility

An offer may be projected only when:

- the player is the intended listener/eligible observer;
- the same NPC is the conversation target;
- the lifecycle response window/beat remains valid;
- required authoritative facts/knowledge are available;
- disclosure/privacy rules allow the answer;
- the offer is still meaningful in current context;
- the candidate survives existing Suggestions bounds/ranking.

## Typed input

Typed player text must not require pressing a generated button first.

The existing NLU/IR path should resolve utterances such as “where are they?” or “what happened?” against the open event beat via context-reference/follow-up resolution.

If the utterance is unrelated, preserve/suspend/expire the event beat according to existing lifecycle rules; do not force-match it.

## Clicked input

Generated buttons carry stable semantic frames. Clicking them uses the existing semantic-frame input path and the same answer resolver as equivalent typed language.

Typed and clicked equivalents should converge on the same response plan where appropriate.

## Grounding

Follow-up answers must distinguish:

- event facts known at event time;
- current volatile facts requiring re-observation;
- private/unknown facts that cannot be disclosed.

No answer is generated from the prior prose string itself.

## Expiry

Use existing lifecycle/window time/turn policy where possible.

Do not retain event context forever merely because the NPC spoke once. Significant world/faction events may separately become Knowledge/memory through their existing owners.

## Acceptance examples

### Horde

1. authoritative horde observation is produced;
2. semantic combat/horde response is selected once;
3. NPC delivers the line;
4. lifecycle records eventRef + facts + follow-up offers;
5. same player talks to NPC;
6. “Where are they?” is offered and/or typed;
7. answer uses/revalidates authoritative threat/location facts;
8. no SocialFlavor prose selection occurs.

### Incapacitated

1. health state produces grounded semantic distress response;
2. offer includes medical need / attacker follow-ups only when known;
3. player asks “What do you need?”;
4. normal semantic answer resolves against health facts;
5. no health truth is duplicated in dialogue state.

### Leader loss

1. faction/leader-loss event ref is canonical;
2. semantic grief/succession reaction is selected;
3. follow-up “What happened?” uses the same event ref;
4. “What now?” may use current faction/succession authority;
5. event history is not stored as rendered transcript.
