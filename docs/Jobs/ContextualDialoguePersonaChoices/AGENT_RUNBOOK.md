# Agent Runbook — Contextual Dialogue Persona & Choices

## Parent objective

The assignment is the **complete developer-side goal**, not whichever phase is currently being worked on. Work one bounded coherent chunk at a time, validate it, record evidence, and continue automatically through all mandatory roadmap phases.

A phase passing does not complete the parent goal.

Only hand back **READY FOR USER LIVE TEST** when every developer-implementable requirement in this job is complete and verified. Native Project Zomboid SP/MP gameplay validation remains user-owned.

## Repository and Git rules

Root `AGENTS.md` is authoritative.

- Existing `main` only; **never create a new branch**.
- Inspect local branch, HEAD, upstream, remote, and user/concurrent work before edits.
- No blind `git pull`, destructive reset, rebase, stash, force push, or worktree/branch workaround.
- Preserve unrelated user/agent changes.
- Commit coherent implementation + documentation slices when safe.
- Do not install, upload, republish, or request authorization for Steam Workshop content.
- Do not launch or operate native Project Zomboid as an agent acceptance workaround.
- **Do not create or update a checked-in `GOAL_PROMPT.md`.**

## Ownership rules

### Existing authoritative state remains authoritative

Do not create duplicate persistent personality, relationship, role, identity, knowledge, trader, or dialogue-state databases.

- Identity owns identity/gender data.
- NPC Traits owns discrete traits.
- Social Profile owns persistent personality dimensions.
- Relationships owns directed approval/respect/familiarity/state/memories.
- Existing actor/capability owners determine companion/owned/hostile/task/action eligibility.
- Dynamic Trading owns trader-specific domain state.
- Conversation/Semantics owns dialogue context and typed semantic routing.
- Gameplay/server handlers remain the only side-effect owners.

The new actor/speech context is a **bounded read-only projection/compiler**, not a state owner.

### Meaning and wording are separate

The semantic response plan or semantic click frame owns **what the utterance means**. Persona/style may change **how that meaning is realized**, never the underlying fact, authorization, action, target, or gameplay result.

Gender must not be used as a personality stereotype. Use it only where identity, grammatical realization, pronouns, compatibility, or explicit authored rules require it.

### One choice path

Preserve the existing path:

`typed/NPC result -> candidate providers -> constraints/privacy -> rank/dedupe -> localized presentation -> Core choicesPart -> semantic_click_frame -> existing DialogueInput -> existing authority/action owner`.

Do not add a second parser, second response generator, second choice widget, second translation backend, second action dispatcher, or button-specific gameplay lane.

## Performance and persistence

- No per-frame NLP/choice generation.
- No per-tick all-NPC persona compilation.
- Recompute bounded actor/speech context on conversation/actor/relationship/profile revisions or turn-driven demand.
- Do not persist derived speech dials or candidate catalogs in ModData.
- Keep candidate/source/trace bounds explicit.
- Reuse translation caches and existing Core/Hoomans localization infrastructure.

## Validation discipline

The existing Semantic Lab and real Lua worker are mandatory acceptance tools. Python-only previews or scratch JSON do not prove runtime behavior.

For every implementation slice:

1. run focused unit/contract tests;
2. run affected Lua/Python regressions;
3. exercise the real production Lua worker for changed semantic behavior;
4. use the existing Tk Semantic Lab under Xvfb when UI behavior changes;
5. verify EN/TL and fallback diagnostics when text changes;
6. verify stale/replay/privacy/authority behavior when candidate or click policy changes;
7. run Kahlua/`luac5.3`, doctor, and bounded performance checks at final gates;
8. record skipped/unavailable evidence honestly.

## Stop conditions

Stop only for a genuine safety/authorization blocker, unsafe repository divergence/concurrent ownership conflict, missing required external capability with no valid fallback, or full developer-side completion.

Do not stop because an individual phase passed, documentation was updated, unit tests passed, or native PZ is unavailable.


## Corrective behavioral-completion rules

The prior P7 handoff is superseded by the 2026-10-22 corrective audit. Do not report READY FOR USER LIVE TEST until P8 in ROADMAP.md passes.

### Companion bond

- Preserve existing detailed starting relationship kinds; do not migrate them into only three stored values.
- Derive the coarse speech class friend/family/lover transiently.
- Family subtypes use localized term metadata and generic family phrase families.
- Never assume family or lover means current relationship state friend.
- Never derive gameplay ownership/authority from bond class.

### Harness parity

Normal Semantic Lab relationship state must come from the production RelationshipStates resolver using approval/respect/familiarity plus the previous/current state needed for hysteresis.

Do not keep a normal user-editable independent state field that can contradict the production resolver.

### Visible-behavior acceptance

A style dial is not complete because its value appears in an inspector. It must either:

1. materially influence an authored realization/rank/eligibility rule covered by tests; or
2. be marked informational/not speech-affecting in the UI and docs.

Do not use hello-only tests as proof that persona affects normal dialogue.

### Provider completion

Do not add more hard-coded provider IDs to the central suggestion builder. New provider work must move toward generic registry collection.


## P9 execution rules — UI-first conversation testability

The previous P8E developer handoff is superseded by the user-facing P9 audit.

Do not report READY FOR USER LIVE TEST until P9A-P9G pass.

### Fix semantics before polish

The typed `conversation_category` self-nesting is an actual routing defect, not merely a Tk label/layout problem. Fix and test that route before treating UI cleanup as accepted.

### Deliver a usable graph early

P9B is intentionally an early user-test checkpoint. Once P9A is green, prioritize getting the real selected ConversationBlock visible in Simulation through the existing graph primitives before deeper renderer refactors or cosmetic polish.

### Reuse, do not parallelize

- one Semantic Lab app;
- one real Lua worker;
- one Conversation Registry;
- one semantic click route;
- one shared graph renderer/model family;
- one translation manager;
- one authoritative conversation state.

Do not create a Python conversation simulator, second graph engine, browser viewer, or direct node-transition shortcut.

### Harness-only full graph

The full future conversation tree is developer tooling. Do not broaden the normal in-game semantic projection to expose future branches or private/hidden information.

### User-visible acceptance beats internal claims

A passing graph-model test is not enough. P9B/P9E require real Tk/Xvfb evidence showing the conversation graph and choices in the actual Simulation layout.


## P10 execution rules — semantic hub replacement and structured UX

The P9 READY FOR USER LIVE TEST handoff is superseded.

Do not report the parent ready again until P10A-P10G pass.

### Legacy What's Up is deletion work, not compatibility work

The user explicitly requires removal of the old authored What's Up implementation.

Do not:

- keep `projecthoomans:whats_up` registered but hidden;
- add a compatibility alias from the new hub back to the old category;
- keep `conversation.whats_up` as a deprecated candidate;
- preserve old block IDs solely to satisfy historical tests;
- create a second legacy/new switch.

Remove or migrate the live references and rewrite tests to the new contract.

If old prose is still useful, re-author it under the correct semantic/provider owner with new IDs.

### One hub over existing owners

What's Up hub activation is a presentation/choice aggregation boundary.

It may collect from existing semantic/provider owners, but it does not own:

- gossip facts;
- wellbeing facts;
- NPC health;
- needs;
- world events;
- Dynamic Trading state;
- quest state;
- relationship mutation;
- gameplay authority.

Do not create a second parser or duplicate those systems.

### Structured-first UI

Normal simulation state must use typed controls derived from worker/runtime metadata where practical.

Raw JSON is Advanced mode, never removed.

Do not solve the usability problem by merely adding validation messages to free-text/JSON fields.

### Early usability priority

After P10A, implement P10B and P10C before broad polish.

The user should receive a usable contextual hub and intuitive common sliders/comboboxes early in P10.

### Real UI acceptance

P10C/P10D/P10E require actual Tk/Xvfb interaction evidence.

Do not declare success from schema/unit tests alone.


## P11 execution rules — actors, dynamic bonds, and runtime-parity UX

The P10 READY FOR USER LIVE TEST handoff is superseded.

Do not report the parent ready until P11A-P11H pass.

### No manual normal-mode bond fabrication

Normal Semantic Lab must not allow arbitrary bond promotion through a plain bond dropdown.

- family comes from actual authored/pre-existing relationship data;
- friend is earned by production relationship progression;
- lover comes from proposal + acceptance;
- direct bond mutation is permitted only in clearly labeled Advanced/Malformed fixture mode.

### No hypothetical production kinds

Do not expose cousin/grandmother/partner/spouse/etc. as normal selectable kinds unless a current production owner can actually produce them.

Extensible registry APIs are fine. User-facing production catalogs must remain truthful.

### Relationship milestone mutations are server-owned

Friend promotion and lover proposal outcomes must use the existing server relationship service/commit/persistence boundary.

Do not mutate durable bond solely in Tk, client dialogue presentation, or parser code.

### Romance uses existing compatibility

Do not introduce a separate romance compatibility database.

Use existing gender + player/NPC social-profile orientation/trait compatibility APIs.

Compatibility alone does not create lover state.

### Generated personality is default

Normal NPC simulation uses production-generated personality from seed/archetype/traits.

Manual numeric personality values are explicit override/debug state.

### Both actors are first-class

Player and NPC Target each need proper needs + Personality & Traits surfaces where production supports those fields.

Do not keep player state as an afterthought under generic World fields.

### UI cleanup is product work

Preview, Snapshot, Restart worker, World Knowledge refresh, Sweep, Persona Matrix and Capture Baseline may remain as capabilities, but not as unexplained primary workflow controls.

Move them to Diagnostics, relevant inspector tabs, or the Compare surface.

### Graph acceptance

A blank graph for a live semantic Flow or hub is not acceptable merely because ConversationBlock graph tests pass.

P11F requires real runtime Flow, Hub, and ConversationBlock adapters.
