# Roadmap — Semantic Interaction Lifecycle

**Parent status:** ACTIVE — P0–P9 lifecycle foundation retained; P10 native Conversation parity and P11 no-split semantic authority consolidation are mandatory.  
**Foundation:** Contextual Dialogue Persona & Choices P14 accepted.  
**Completion rule:** phases organize work; completing a phase never completes the parent goal. Continue autonomously through every mandatory phase until developer-side acceptance or a genuine blocker.

## P0 — Migration inventory + performance/persistence baseline

Audit every existing flavor/spontaneous speech route and establish current costs/state ownership before changing behavior.

Required:

- complete the migration matrix from actual source;
- identify duplicate greeting/emote/social reaction owners;
- inventory presentation/TTS/cooldown/authority paths;
- capture current Semantic Lab behavior for representative greeting, farewell, emote, combat event and ordinary typed conversation;
- establish baseline pair/thread/persistence/network diagnostics where currently measurable;
- add focused characterization tests only where needed to prevent behavior loss.

**Gate:** machine-readable or clearly auditable inventory exists; representative old and semantic paths are reproducible through production Lua; no migration is hidden in the baseline.

## P1 — Unified semantic interaction envelope

Add/adapt one bounded production contract for typed/button/emote/lifecycle/event interaction meaning.

Required:

- typed/headless text continues through current NLU;
- semantic buttons retain the current shared semantic-frame route;
- known emotes/lifecycle/world events enter after NLU;
- envelope carries source, actor/target, semantic act/topic/event refs and bounded metadata;
- no gameplay authority is granted by the envelope;
- NPC output retains semantic provenance for follow-up interpretation.

**Gate:** equivalent typed/button/emote/headless inputs can resolve to the same semantic meaning where appropriate, without duplicate execution paths.

## P2 — Conversation lifecycle greeting + farewell migration

Use conversation-open/close as semantic lifecycle events.

Required:

- make existing semantic greeting flow the actual opening intelligence;
- preserve first-contact/relationship/persona/context behavior;
- migrate farewell eligibility/chance/cooldown/timing into lifecycle policy as appropriate;
- add semantic farewell response plan/realization;
- contextual reply offers work after generated NPC speech;
- prove single presentation/TTS output;
- retire duplicate greeting/farewell prose authority only after parity.

**Gate:** opening and closing conversation through production Lua uses semantic ownership and correct context; legacy duplicate generation is no longer authoritative.

## P3 — Emote/social gesture migration

Migrate player/NPC social gestures and overlapping companion-command flavor.

Required:

- wave, thanks, thumbs-up/down, insult, salute, clap and other real registered gestures use typed semantic acts;
- current authored EN/TL lines become seed realization variants where semantically valid;
- gesture response interprets active beat/thread first when one exists;
- gameplay command/action authority remains with existing owners;
- typed equivalent and gesture equivalent can converge on the same beat outcome.

**Gate:** emotes are contextual conversation inputs, not a separate flavor intelligence path.

## P4 — Grounded spontaneous event reaction migration

Migrate representative combat/medical/social/world reactions.

Required:

- event owners provide grounded facts/refs;
- semantic reaction providers map facts to dialogue acts/plans;
- no fake text is fed back through NLU;
- speaker arbitration/cooldowns bound how many witnesses actually talk;
- preserve compatibility adapters and authority;
- integrate shared world/gossip refs instead of duplicating event truth.

**Gate:** representative event-trigger speech is produced through semantic response planning/realization and remains grounded in authoritative event facts.

## P5 — Thread + beat continuity

Introduce bounded active interaction lifecycle.

Required:

- active thread;
- current/suspended beat stack;
- open questions;
- recent bounded semantic turns;
- response windows;
- topic interruption/suspend/resume;
- UI close/interruption can suspend rather than destroy context;
- NPC-generated speech keeps semantic metadata for later reply resolution;
- visible transcript size does not govern semantic continuity.

**Gate:** a conversation can be interrupted, answered via different input modes, resumed and continue coherently without relying on hidden transcript text.

## P6 — Compaction, multi-day suspension + memory promotion

Add warm/cold lifecycle behavior.

Required:

- semantic-turn compaction;
- sparse suspended pair capsules;
- lazy expiry/time decay;
- significant-memory promotion;
- structural fact/Knowledge promotion;
- commitment handling through correct authoritative owner;
- forgetting of trivial resolved interaction;
- anti-repeat realization history remains bounded and distinct from autobiographical memory.

**Gate:** multi-day interaction continuity works while a long conversation and repeated trivial exchanges remain bounded.

## P7 — Multiplayer sparse persistence + network isolation

Prove scale and authority.

Required:

- no Player × NPC preallocation;
- create pair record only after meaningful durable delta;
- delete empty pair records after compaction;
- NPC-global state stored once;
- player-private pair/Knowledge context not broadcast to unrelated clients;
- simultaneous players can have distinct threads with one NPC;
- shared events use deduplicated references;
- server owns durable lifecycle commits;
- no per-NPC per-tick semantic/memory work.

**Gate:** sparse multi-player state and bounded network projections pass production-Lua stress tests.

## P8 — Semantic Lab lifecycle/memory workbench + stress acceptance

Extend the existing Semantic Lab rather than create a new harness.

Required:

- inject typed input, semantic choice, emote, lifecycle event and grounded event through production paths;
- inspect active thread/beat/open questions/commitments;
- inspect compaction/promotion/expiry;
- inspect memory/pair-state budgets;
- run long-conversation and multi-player/many-NPC stress scenarios;
- use save-backed P14 production rehydration where relevant;
- keep source save immutable;
- Python fixtures engine boundaries only.

**Gate:** an agent can explain why an NPC remembered/resumed/replied and can measure bounded state through the real Lua worker.

## P9 — Retire legacy flavor authority + final developer acceptance

Remove or reduce duplicate legacy intelligence only after all migrations have parity.

Required:

- legacy SocialFlavor/command/emote/farewell text owners no longer compete for migrated families;
- remaining compatibility shims are narrow and documented;
- ConversationBlocks authority is preserved;
- EN/TL parity;
- no duplicate speech/TTS;
- no semantic/gameplay authority regression;
- full focused regression suites and performance/persistence stress gates pass;
- user-facing live-test handoff prepared.

**Gate:** one production semantic interaction lifecycle owns migrated spontaneous dialogue, bounded continuity and sparse persistence. Only final native user acceptance remains.

## P10 — Native Conversation parity correction

**Status:** ACTIVE.

The first user native/harness comparison after P0–P9 exposed a developer-side acceptance gap. See \`NATIVE_CONVERSATION_PARITY_CORRECTION.md\` for the detailed source audit, architecture and chunk sequence.

Mandatory subphases:

- P10A — reopen acceptance + freeze parity evidence;
- P10B — headless production Conversation presentation projection;
- P10C — Semantic Lab primary Conversation consumes the native projection;
- P10D — click/session parity;
- P10E — opening/close/suspend/resume parity;
- P10F — conversation-first Simulation desktop UX redesign;
- P10G — World Browser navigation repair;
- P10H — native-versus-harness parity acceptance.

**Gate:** the Semantic Lab main Conversation surface is a trustworthy behavioral mirror of the production native Conversation session for the same state. Broader candidates remain diagnostics only, layout remains stable through real workflows, and World Browser role/affiliation navigation is explicit.

P10 is intentionally extensible while the user continues the current planning/audit pass. Additional approved corrective subphases may be appended before final goal generation.

## P11 — Legacy semantic authority consolidation

**Status:** MANDATORY.

A post-P10 audit found that several migrated families still use old Flavor/SocialFlavor classifiers or reply-ID selectors to choose the response before attaching semantic lifecycle provenance. This is a split system.

See `LEGACY_SEMANTIC_AUTHORITY_CONSOLIDATION.md`.

Mandatory subphases:

- P11A — remaining authority inventory;
- P11B — canonical semantic realization boundary;
- P11C — greeting/farewell authority migration;
- P11D — emote/companion/social reply authority migration;
- P11E — combat/medical/distress/leader-loss classifier migration;
- P11F — reduce SocialFlavor to content/presentation backend;
- P11G — remove misleading/dead remnants and sanitize execution docs;
- P11H — no-split-system acceptance.

**Gate:** semantic context/flows/response plans are the only conversational intelligence authority. Flavor/SocialFlavor may retain authored content and low-level delivery only.

P10 and P11 are both mandatory and may be interleaved by dependency.

## Stop condition

Do not stop because:

- P0 inventory is done;
- greeting migration passes;
- one flavor family moves;
- one long-thread test passes;
- the harness is green for a partial slice.

Stop only when P0–P11 and any later user-approved mandatory corrective phases have developer-side acceptance, or a genuine external/technical blocker prevents further safe progress. P0–P9 passing alone is no longer sufficient, and attaching semantic provenance to a legacy-selected reply does not count as semantic migration.

