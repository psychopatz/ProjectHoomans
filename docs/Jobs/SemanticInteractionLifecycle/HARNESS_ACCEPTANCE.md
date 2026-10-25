# Semantic Lab Acceptance — Interaction Lifecycle

## Latest P12 regression evidence — 2026-10-25

The production worker now preserves a typed landing shortcut frame through the
native/group submission boundary. A direct click of
`conversation.landing:whats_up` resolves through the semantic response and
realization catalogs rather than the generic `Let me think about that.`
fallback. The companion authority context also accepts a native target entry
whose bounded replicated snapshot is present without a local record, so the
Orders hub is projected from the same authoritative client facts used by the
command affordance gate.

The P12 harness suite is **29/29** and the focused production Lua suite is
**12/12**. Native SP/MP execution remains user-owned.

The existing Semantic Lab and its production Lua worker are the primary development/debug surface for this job.

P14's rule remains mandatory:

> **Fixture the engine, never fixture the mod.**

Python may discover, transport, isolate, drive and present state. Production Lua must own Project Hoomans semantic lifecycle, compaction, persistence, memory promotion, context derivation and gameplay-facing decisions.

## Required observable inspectors

The harness must be able to show, where relevant:

- input source: typed/button/emote/lifecycle/event;
- canonical semantic act/frame;
- actor and target;
- active thread ID/status;
- active/suspended beat;
- current topic/topic stack;
- open question/commitment refs;
- recent semantic turns;
- compaction result;
- residue and lazy-decay provenance;
- promoted memory/fact/event refs;
- ActorConversationContext;
- selected response pool/plan/realization;
- recent-variant exclusion;
- contextual reply offers;
- actual production action/transport side effects;
- pair-state/persistence budget counters.

Do not persist these diagnostic traces into normal game ModData.

## Mandatory scenarios

### A. Multi-input contextual reply

NPC emits one semantically tagged line.

Respond separately through:

- typed Talk;
- a semantically equivalent choice button;
- an appropriate emote;
- headless text input.

Where the meanings are equivalent, the same active beat/semantic outcome should be selected without duplicate gameplay effects.

### B. UI transcript independence

Run more turns than the visible transcript limit.

Discard old displayed rows.

Verify the current thread/beat can still resolve a correct reply using compact semantic state, not hidden UI text.

### C. Interrupted topic

Start topic A, interrupt with topic B, resolve B, then resume A.

Verify bounded suspend/resume and no unrelated identity/relationship side effects.

### D. Multi-day resume

Start an unresolved meaningful topic.

Suspend/compact it.

Advance world time by hours/days using the existing harness world-time fixture.

Rehydrate/resume and verify context-sensitive continuation.

Trivial old turns must not be required.

### E. Forget trivial interaction

Run ordinary greeting/thanks/small talk with no meaningful delta.

After compaction, verify no unnecessary pair record remains.

### F. Promote significant interaction

Exercise a safe representative significant event/commitment/fact.

Verify the lifecycle promotes only the compact authoritative representation and can later reference it without restoring the old transcript.

### G. Long conversation bound

Run at least 200 semantic turns through the production worker.

Verify:

- recent-turn bound holds;
- compaction occurs;
- open state remains correct;
- serialized pair capsule remains bounded;
- no linear retained transcript/debug growth.

### H. Multiplayer sparse pair stress

Use production Lua state with a representative stress model equivalent to multiple players and hundreds of NPCs.

Minimum product question to answer:

> Do possible pairs remain absent until meaningful interaction, and does durable state scale with meaningful activity rather than Player × NPC?

Verify:

- no preallocation cross-product;
- independent pair context for simultaneous players;
- no private pair context leak;
- bounded pair counts after many trivial exchanges;
- empty pair-state garbage collection.

### I. Shared event dedupe

Create one canonical shared world/faction/gossip event known by several actors.

Verify memory/knowledge uses refs or the existing canonical event owner rather than duplicating large payload/prose.

### J. Dormant cost

Demonstrate that creating/loading hundreds of dormant NPCs does not start semantic per-tick lifecycle work.

Instrument event/hydration counts or equivalent bounded diagnostics.

## Performance/persistence evidence

Record at least:

- turn resolution time distribution for representative semantic interactions;
- hydration and compaction timing;
- materialized pair-record count;
- approximate serialized lifecycle size where practical;
- long-thread retained-state size before/after compaction;
- network projection size where practical;
- number of trivial turns discarded;
- number of promoted memories/facts;
- zero per-tick full-NPC semantic scans.

Do not optimize toward a fake Python benchmark that bypasses production Lua.

## Save-backed acceptance

Where real-save actor state matters:

- source save remains byte-for-byte immutable;
- isolated working world may mutate;
- production Lua owns record deserialization and semantic context;
- Reset restores the imported baseline;
- no Python reinterpretation of Project Hoomans ModData.

## GUI availability

A missing attached desktop is not a project blocker.

Use the existing worker/CLI/Xvfb routes for developer evidence when necessary, but do not claim unrun visual behavior.

Final native Project Zomboid SP/MP remains user-owned after all developer gates are complete.



## Native Conversation parity acceptance

The primary Simulation Conversation surface is now an acceptance target, not merely a convenient UI.

### K. Presented-choice parity

For one fixed save-backed Player/NPC state:

1. obtain the production headless Conversation presentation;
2. render the Semantic Lab primary Response Channel from that projection;
3. compare against native user evidence when available.

Require parity for:

- current semantic group;
- choice IDs/frames;
- resolved labels/text;
- ordering semantics;
- enabled/disabled state;
- revision;
- navigation/back rows;
- intentional root owned actions.

The main surface must not render unrelated global candidates. Full candidate sets belong in diagnostics.

### L. Opening parity

Loading a saved target must not itself masquerade as an opened conversation.

Explicitly open/start Talk and verify:

- production Talk route;
- staged opening/greeting;
- conversation log state;
- lifecycle/busy state;
- relation presentation;
- first Response Channel projection;
- TYPE TO TALK availability.

### M. Click/session parity

For a displayed row verify:

- exact production frame submission;
- busy guard;
- disabled guard;
- revision/stale rejection;
- duplicate receipt rejection;
- rejected-choice reprojection/restoration;
- next production-presented choices.

Do not use worker response type as the semantic validity rule.

### N. Layout stability workflow

At supported desktop geometries perform:

~~~text
load saved NPC
-> open conversation
-> drag layout
-> click response
-> type response
-> change/apply a workbench setting
-> continue conversation
-> switch context tab
-> return
~~~

Verify:

- user splitter/dock position does not snap back after ordinary operations;
- hiding controls reclaims their space;
- conversation/transcript remains the dominant readable surface;
- response channel remains usable with variable row counts.

A non-zero transcript height is not sufficient acceptance.

### O. World Browser navigation parity

Verify role/relationship navigation exposes at least:

- companions/player faction;
- settlers/communities;
- hostile/looters;
- traders/providers;
- neutral/unaffiliated.

Also preserve saved affiliations/factions, communities and overlays as explicit alternate navigation, without a persisted lens making the primary classification appear missing.

### P. State-specific native fixture

The user-supplied 2026-10-25 native screenshot provides one concrete parity fixture:

~~~text
NPC: Pete Patz
opening: "Hey. Need a hand before we wrap up?"
presented choices:
- Tell them to leave the group
- That's all. Stay safe.
- What's up?
typed input: available
native current-relation presentation: visible
~~~

The harness must reproduce the production-presented semantic state for that same saved pair/state when the corresponding save is available. This fixture does not hard-code those choices globally.

## Acceptance reopening

Earlier P0–P9 automated evidence remains useful implementation evidence, but it did not prove native Conversation-surface parity.

Therefore the previous READY FOR USER LIVE TEST conclusion is superseded until P10 passes.


## No-split semantic authority acceptance

For representative greeting, farewell, emote, command acknowledgement, combat reaction, medical/distress reaction and leader-loss reaction, diagnostics must show:

~~~text
grounded facts
-> semantic act/topic
-> active beat/thread
-> response plan
-> realization family/ID
-> renderer/delivery
~~~

The renderer must not be the first component that decides relationship stance, need/grief bucket or response family.

Add focused acceptance for:

- equivalent typed/button/emote meaning converging before realization selection where appropriate;
- renderer substitution not changing semantic response plan/realization family;
- static guards against legacy reply-family selection before semantic planning;
- guards against Flavor-only audience/need/grief classifiers controlling migrated response families;
- one unmistakable current active goal in root execution policy;
- cleanup/relocation of obsolete duplicate harness modules after dependency verification.

The project cannot return to READY FOR USER LIVE TEST until P10 proves native Conversation parity and P11 proves that mirrored production behavior has one semantic conversational-intelligence owner.


## P12 — native action & semantic capability acceptance

### V. Authored action execution

Exercise production-presented authored capabilities through the same session used by native Conversation.

Farewell acceptance must prove:

- row is presented;
- one capability/action dispatch occurs;
- NPC response is delivered when defined;
- close flag/reason survives semantic decoration;
- production Conversation lifecycle becomes closed;
- presented rows clear appropriately.

Departure acceptance must prove:

- initial row executes;
- warning/preview state is reached;
- confirm/cancel semantics are preserved;
- confirm calls the existing server-authoritative departure service once;
- successful departure closes the Conversation;
- relationship/faction consequences remain owned by the existing service.

### W. Semantic speech delivery

The emote regression must cover the production queue boundary: the selected NPC reply is not dropped by player-emote/ambient family arbitration, is pumped when the native interaction requires immediate feedback, and is visibly delivered exactly once. The harness must inspect the production delivery seam and ownership metadata rather than treating a result or diary record as speech delivery.

For semantic emote and other resolved NPC speech:

- realization family/ID selected once;
- resolved text delivered once;
- active Conversation receives/logs it when appropriate;
- world nameplate/bubble delivery works when no active Conversation owns the exchange;
- TTS remains downstream;
- diary/debug recording is not accepted as a substitute for visible delivery.

### X. Semantic address

Test unrevealed identity through all player-facing speech paths.

Require:

- no ordinary speech leakage of `Unknown survivor`;
- neutral `stranger`-family fallback;
- constrained variation such as mate/pal and gendered forms only when eligible;
- no invented identity;
- recent-address repetition remains bounded;
- EN/TL/localization path remains valid.

### Y. Companion Orders

Native/harness capability projection must show one root navigation row for Companion Orders rather than independent Follow/Stay/Wait root rows.

Inside the group:

- authoritative following state -> Wait here;
- non-following commandable state -> Follow me;
- Camp shown only when capability is meaningful;
- Go Home shown only when eligible;
- Back/navigation works.

After execution, reproject from authoritative state and verify the toggle changes.

Opening Orders, opening Camp, and returning with Back are semantic conversational exchanges. Each accepted navigation frame must produce exactly one player transcript line and exactly one contextual NPC acknowledgement before the requested group is shown. A Camp branch with no currently valid sites must speak a bounded fallback and show no fabricated destination rows.

### Z. Dynamic Camp

The harness fixtures the production `semantic_location_observation` primitive contract when exercising dynamic destinations. Production Lua owns the client observation adapter and the server remains the authority; Python may provide bounded primitive room/campfire observations but must not scan the map or choose a destination. Native and headless projections therefore consume the same `campSiteCandidates` shape and stable `siteID`/`roomID`/`campfireID` identity.

Using production CampSite adapters:

1. enumerate bounded loaded valid rooms/campfires;
2. present semantic labels;
3. choose one;
4. send primitive site identity/hint;
5. server revalidates;
6. authoritative camp order commits the selected validated site.

Also test stale/invalid hint rejection and generic fallback behavior.

The dynamic discovery regression must assert that an unspecified Camp menu query does not become the literal room-name filter `"room"`; valid rooms such as `HALLWAY` must remain eligible for projection.

Opening the Camp branch itself must also be covered: valid destinations are projected dynamically only after the semantic acknowledgement, and every destination selection must deliver the authoritative Camp acknowledgement/result rather than merely toggling a UI row.

### AA. Equivalent capability invocation

Where semantically equivalent, typed text, semantic button and headless request must resolve to the same capability ID and authoritative executor.

Example:

- button: Camp in the living room
- typed: "Make camp in the living room."
- headless semantic frame: CAMP + living-room target

No duplicate gameplay path is allowed.

### AB. Native end-effect regression fixture

The user-reported 2026-10-25 failures are mandatory regression tests:

- Goodbye previously failed to close.
- Leave Group previously failed to complete expected behavior.
- emote semantic response previously was not visibly delivered.
- unknown-name placeholder previously leaked into speech.
- companion movement rows were structurally contradictory/overexposed.

Do not mark P12 accepted until those regressions are covered by production-Lua/session tests and the harness reflects the resulting production state.
