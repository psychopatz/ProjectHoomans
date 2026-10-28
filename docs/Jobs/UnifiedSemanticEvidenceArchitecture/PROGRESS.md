# Progress — Unified Semantic Evidence Architecture

**Status:** PLANNED / NOT IMPLEMENTED.
**Branch:** existing main.
**Audit anchor:** ProjectHoomans 2bc4810f.
**Current phase:** E0 — baseline, contracts and storage measurements.
**Next exact chunk:** E0A — create production-worker baselines for reset/no-grievance apology, same-session insult->apology, same-day cross-session recall, durable-event recall and saturated relationship-memory behavior; record existing session/day/durable payload shapes and serialized byte deltas without changing production semantics.

## Accepted foundation

Do not redo these systems merely because this goal depends on them:

- PsychopatzCore generic NLU/candidate/DialogueTurn path;
- bounded Hoomans DialogueContextState;
- compact Conversation Memory s/t/l storage;
- Relationship and Conduct authorities;
- InteractionProviders / InteractionContext;
- Pragmatic Resolver / Interaction Director;
- generated affordances / native Response Channel;
- UtterancePlan / Dialogue Content / CodeBuilder;
- prior Pragmatic Dialogue C0-C11 + L0-L5 developer acceptance.

## Known gaps to prove/fix

- ungrounded APOLOGIZE currently reaches a generic acceptance-like response;
- InteractionProviders has no canonical evidence projection;
- social-event metadata and Conversation Memory event metadata are separately authored;
- most first-party social events can fall through dynamic memory typing with salience 0;
- TODAY short retention is recency-only;
- compact today projection depends too strongly on successful detailed relationship-memory retention;
- generic semantic relation/obligation matching does not yet exist;
- interactionJournal is too heavy to become semantic authority.

## Parent completion boundary

Not complete until E0-E7 pass, including synthetic extensibility fixture and storage stress gate. Fixing apology alone is insufficient.

## Safety

No native PZ launch, Workshop publication, source-save mutation, new branch, transcript persistence, new semantic ModData root, or feature-specific parallel resolver/memory subsystem.
