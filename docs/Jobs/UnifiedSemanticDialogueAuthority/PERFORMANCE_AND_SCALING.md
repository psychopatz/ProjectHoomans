# Performance & Scaling Contract

The semantic consolidation must reduce duplicate work, not add another runtime layer.

## Event-time rule

For a known event:

```text
event
→ build bounded semantic context
→ select response once
→ realize phrase once
→ enqueue delivery once
→ record compact lifecycle anchor once
```

Do not re-run semantic selection in the presentation queue, on every UI refresh, or every tick.

## Reuse existing bounds

Preserve existing bounded infrastructure unless measurements justify a change:

- `ResponsePlan.MAX_TURNS = 4`;
- `ResponsePlan.MAX_SEGMENTS = 6`;
- `ResponsePlan.MAX_FACT_REFS = 8`;
- `DialogueContextState.DEFAULT_TURN_LIMIT = 12`;
- `DEFAULT_MENTION_LIMIT = 32`;
- `DEFAULT_FOCUS_LIMIT = 8`;
- `DEFAULT_FLOW_LIMIT = 8`;
- `DEFAULT_FLOW_STACK_LIMIT = 4`;
- `DEFAULT_AGENDA_LIMIT = 8`;
- `DEFAULT_TOPIC_HISTORY_LIMIT = 4`;
- Suggestions `MAX_CANDIDATES = 24`;
- existing lifecycle event/thread/pair limits;
- existing presentation-registry bounds.

Do not raise limits just to make a test pass.

## Sparse lifecycle

- No Player×NPC cross-product.
- No persistent context for NPCs who never interact with the player.
- No per-NPC/per-tick dialogue/follow-up scan.
- Only actual listeners/participants receive relevant pair/thread state.
- Response windows expire/compact through existing lifecycle policy.
- Shared world events are referenced by ID rather than copied per pair.

## Stored data

Allowed compact data:

- IDs;
- event/fact refs;
- semantic topic/act;
- responsePlan/realization IDs;
- bounded offer IDs/frames;
- timestamps/turn sequence/status.

Do not store:

- translation catalogs;
- phrase arrays;
- rendered transcripts;
- complete NPC snapshots;
- duplicated relationship/faction/inventory/health state.

## Suggestion cost

Event follow-up projection should inspect only the current target's active/recent lifecycle context and already-bounded offers.

Do not scan:

- every NPC;
- every world event;
- every ResponseCatalog pool;
- the entire translation tree.

## Content cost

Dialogue Content/translation authoring JSON is compile-time/source-controlled data. Runtime consumes generated bounded Lua/string translation artifacts; do not parse authoring JSON per conversation.

## Multiplayer

- preserve player-private pair context;
- do not broadcast private follow-up/Knowledge context;
- shared event truth is deduplicated;
- authoritative effects remain server-owned;
- client presentation state remains bounded and non-authoritative.

## Measurement gates

Capture before/after measurements for representative:

- worker startup;
- one semantic event reaction;
- follow-up offer projection;
- typed follow-up resolution;
- active Conversation open after event;
- many-event bounded stress;
- many-NPC dormant case;
- serialized lifecycle/pair state where relevant.

Use the accepted Semantic Observatory test-topology discipline: fast headless regression + focused GUI/real-worker acceptance. Test runtime itself must remain practical.

## Performance failure conditions

Migration is not accepted if it introduces:

- new per-tick semantic polling;
- O(all NPCs) follow-up discovery;
- O(all events) conversation-open scanning;
- unbounded event/offer history;
- repeated ResponseCatalog selection for one delivered line;
- persistent text growth;
- materially slower normal regression/startup without measured justification.
