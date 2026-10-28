# Progress — Unified Semantic Evidence Architecture

**Status:** IN PROGRESS — E0 baseline accepted; architecture implementation pending.
**Branch:** existing main.
**Audit anchor:** ProjectHoomans 2bc4810f.
**Current phase:** E1 — canonical evidence schema and provider seam.
**Next exact chunk:** E1A — extend InteractionProviders/InteractionContext with bounded normalized evidence and adapter registration; test SESSION/TODAY/DURABLE normalization before implementing tier adapters.

## E0A accepted (2026-10-28)

- Added disposable production-worker storage fixture and `test_unified_evidence_e0.py`; no native runtime or source saves are used.
- Machine capture: `E0_BASELINE.json`, production semantics at bbaf2cd4. Reset APOLOGIZE gives “Noted. Let's move on.”; same-session insult/apology selects reconciliation; serialized same-day replay retains the compact insult triple but lacks contextual admission.
- Saturation: 20 permanent memories; insult applies immediate effect while detailed memory is pruned and compact TODAY is missing. This confirms the E3 projection defect.
- Durable event projection survives day rollover in `l`; `s` is removed. Existing limits are 8 triples, 6 quadruples, 20 relationship memories, 64 conduct evidence entries. Session shape is captured without copying text/history into persistence.
- Ordinary serialized record: 2693 -> 4354 canonical JSON bytes (+1661). These measure production serializer output transported as canonical JSON, not Java binary allocation overhead. Root set unchanged.
- Worker close/open reloads its source fixture, so cross-conversation persistence is additionally tested by serializing and importing into a new isolated worker. No source save mutation.
- Validation: E0 worker test PASS; social-event smoke PASS. Graph generation 2026-10-24 is stale/untracked for newer semantics/harness files; direct source fallback used for those owners.
- Ranking contracts remain as specified in ARCHITECTURE.md: confidence is certainty, salience retention importance, effective strength domain decay, recency age, contextual relevance ephemeral fit, priority deterministic catalog order.

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
