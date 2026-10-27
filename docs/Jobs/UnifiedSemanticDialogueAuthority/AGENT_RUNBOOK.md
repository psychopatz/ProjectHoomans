# Agent Runbook — Unified Semantic Dialogue Authority

## Operating rule

The parent objective is complete only when Project Hoomans-owned conversational meaning has one semantic authority, Dialogue Content is the one first-party wording authority, and migration-era/legacy dialogue registries, aliases and names have been purged from the production source.

A phase/chunk passing does not finish the parent goal. After each accepted chunk, update `PROGRESS.md` and continue automatically to the next mandatory roadmap phase unless a genuine blocker or explicitly user-owned native gate is reached.

## Mandatory read order

Read root `AGENTS.md`, then this job's `README.md`, `AUDIT.md`, `ARCHITECTURE.md`, `EVENT_FOLLOWUP_CONTRACT.md`, `MIGRATION_MATRIX.md`, `PERFORMANCE_AND_SCALING.md`, `HARNESS_ACCEPTANCE.md`, `P10_CANONICAL_SEMANTIC_CLEANUP.md`, `P11_MODULAR_CONVERSATION_ARCHITECTURE.md`, `P11B0_MODULAR_CONVERSATION_COMPILER.md`, `ROADMAP.md`, and **`PROGRESS.md` last**.

Re-read the relevant current source before editing; historical job prose is not runtime truth.

## Hard invariants

- **No split conversational intelligence.** Semantics chooses meaning; content realizes wording; presentation delivers it.
- Do not add another response catalog, event-chat subsystem, follow-up registry, persistence database or parallel suggestion engine.
- Known world/game events enter after NLU as typed semantic events. Do not stringify known events and reparse them.
- Freeform typed player language remains on the existing NLU/parser/router path.
- Gameplay/domain services remain authoritative for facts, permissions and effects.
- ConversationBlocks retain authored branching/gates/effects/repeat authority.
- Existing SocialFlavor delivery may remain for queueing, cooldown, priority, nameplate, Conversation, TTS and external compatibility, but Project Hoomans semantic-owned events must not depend on it to choose prose/meaning.
- Existing authored text is migration source material. Preserve accepted EN/TL wording where useful by moving it into semantic response/content ownership; do not delete content before parity.
- NPC-initiated event follow-up must reuse `SemanticInteractionLifecycle`, response windows/beats/event refs, `DialogueContextState`, Suggestions and ContextResolver.
- No ordinary rendered text or transcript in NPC ModData.
- No per-NPC/per-tick semantic work.
- Preserve PBrainZ as optional downstream realization/context consumer; it does not become semantic truth authority.
- P10 steady state contains no first-party `PNC_SocialFlavorDefinitions*`, `PNC_ConversationToolReplyCatalog`, `PNC_CompanionCommandFlavor*` wording registry, `PNC.FlavorText*`, `.migrated.` content IDs, `MIGRATED_*` content concepts, or `legacySource` fields.
- Git history is the archive. Do not keep executable legacy files in `media/lua` merely as migration/source material.
- Studio grouping is a derived view over canonical semantic IDs; do not create another hierarchy authority.
- P11 must not create a second wording editor, Conversation UI authority, or agent-only patch path. GUI and agents use the same bounded authoring service.
- Conversation UI Registry may own presentation/navigation structure and references to registered predicates/providers, but never gameplay/domain eligibility or effects.
- `generated` is provenance, not semantic meaning; canonical IDs must describe conversation/domain meaning.

## Migration discipline

For each legacy family:

1. identify the authoritative event/game facts;
2. identify exactly what the old Flavor/ToolReply/registry code currently decides;
3. map/reuse the canonical semantic response pool/flow and context provider;
4. move meaning-equivalent wording into Dialogue Content/translation ownership where appropriate;
5. attach grounded fact refs, event refs, semantic plan/realization IDs and optional follow-up offers;
6. route the producer through semantic selection **once**;
7. deliver the already-selected realization through the existing presentation queue;
8. add real-Lua/harness parity and no-fallback tests;
9. retire the old decision API only after caller analysis proves no semantic-owned production dependency remains.

Do not count “legacy chose a Flavor ID, then semantic provenance was attached afterward” as migrated.

## P10 cleanup discipline

For deletion/rename work, prove current callers before editing, migrate useful behavior to its canonical owner, then delete the old source and update tests in the same coherent slice. Do not leave compatibility shims inside Project Hoomans after all internal callers are migrated merely to preserve old names.

When compacting Dialogue Content, treat ResponseCatalog as semantic topology authority and the content source as wording authority. Studio must join those sources at read time instead of copying semantic conditions, priorities, pool ownership and migration provenance into every phrase record.

Use the P9 resource-aware Python runner for broad acceptance. Do not reintroduce the old serial full-suite gate.

## Follow-up discipline

A follow-up offer exists only when:

- the NPC actually delivered a semantic event response;
- the player/listener context is eligible;
- authoritative facts exist to answer it;
- the existing lifecycle response window/beat is still valid;
- privacy/knowledge/disclosure policy permits the answer.

Use response-plan offers / existing suggestion providers and existing pending-follow-up/context-reference resolution. Do not invent a second event-follow-up interpreter.

Interruptions should preserve or expire the existing semantic beat according to lifecycle policy. Current-state questions must revalidate volatile facts when appropriate; historical event facts remain historical refs.

## Performance discipline

Follow `PERFORMANCE_AND_SCALING.md`.

In particular:

- resolve semantic meaning once at event time;
- no render-time ResponseCatalog re-selection;
- no broad catalog scans on conversation open;
- no new global per-NPC polling;
- use existing bounded lifecycle limits;
- store compact IDs/refs/offers, not text;
- profile worker startup/event resolution/follow-up projection before expanding caps.

## Testing discipline

Use production Lua through the existing worker. Python may drive/isolate/present and fixture engine boundaries; it must not implement gameplay or semantic authority.

Add characterization tests before deleting old behavior. Acceptance must prove both positive migration and negative absence of legacy fallback.

Use the split fast headless + focused Xvfb topology established by `SemanticObservatoryDialogueQuality/TEST_RUNTIME_PERFORMANCE.md`; do not normalize a slow suite by adding broad timeouts.

## Git/safety

- Existing `main` only.
- Reconcile dirty/concurrent work before editing.
- Never reset/stash/discard uncertain user or agent work.
- Do not mutate source saves.
- Do not launch native Project Zomboid.
- Do not publish Steam Workshop content.
- Do not add goal progress to root `AGENTS.md`.
- Commit coherent slices only after validation.

## P11 authoring discipline

Treat P10 runtime behavior as accepted foundation. P11 should simplify source
and tooling while preserving semantic/gameplay authority.

For each P11 migration:

1. identify the current canonical semantic/content/navigation owner;
2. identify every caller and generated artifact;
3. add service-level characterization before moving source;
4. migrate one coherent domain/surface;
5. keep stable canonical IDs where externally/runtime significant;
6. generate rather than hand-edit runtime Lua/translation artifacts;
7. validate typed/clicked/runtime parity;
8. remove the superseded source/path in the same slice;
9. run the full native Lua suite after every coherent wording/runtime migration slice; any pre-existing behavior regression rejects the slice;
10. update `PROGRESS.md` and continue automatically.

Recovery-specific rules:

- The verified restart point is recovery commit `18eacad50745e445c92639d1ce77d487d1da07fd`, whose tree matches P11A anchor `08081ac8` and passed native Lua `897/897`.
- Do not recreate the rejected P11B big-bang wording migration. Migrate one small caller/domain family at a time and keep the old path until the new path proves parity.
- Do not create a broad `runtimeAliases` / translation-key compatibility registry as a permanent or phase-wide substitute for migrating callers. If an externally consumed public key truly requires compatibility, stop and document that exact API boundary for user decision.
- Do not rewrite existing regression expectations merely because a new translation key or fallback string differs. First prove the user-visible/semantic contract remains equivalent; otherwise the change is a regression.
- Do not create P12, a new parent phase, or any mandatory scope beyond P11A–P11I without explicit user approval. New ideas belong in notes only until approved.

Do not build a generic visual programming IDE. Developer Tools is a contextual
editor for selected Conversation wording/presentation/navigation.

Do not expose raw gameplay predicates as editable JSON implementations. The UI
may select/reference registered predicate/provider IDs and display why a
dynamic choice is locked.

Normal phrase editing must support structural variant operations through safe
service methods; raw JSON remains an optional diagnostic, not the primary
workflow.

## P11B0 modular-generation discipline

P11B0 is a source/compiler foundation, not a wording migration.

- Prefer small canonical Conversation shards over large authoring documents.
- Prefer generated runtime structure, indexes, translation keys, fingerprints
  and manifests over hand-maintained mechanical metadata.
- Generation must be deterministic from an explicit manifest/canonical order;
  do not depend on incidental filesystem enumeration.
- Generated aggregate snapshots are audit/test artifacts only and may never
  become canonical write targets.
- Generated runtime output must be bounded by semantic/domain shards; do not
  replace one giant source with one giant generated registry.
- Stable semantic/content IDs must not depend on physical shard paths.
- Agents and GUI services operate by canonical ID and owning-shard resolution,
  not by hard-coded monolithic filenames.
- P11E owns broad taxonomy/name cleanup. P11B0 only establishes the metadata
  and generation seams needed to make that cleanup safe.
