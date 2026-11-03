# Agent Runbook — Core Semantic & Relationship Foundation

## Parent-goal ownership

Treat the complete cross-repository objective in README/ROADMAP as one implementation assignment.

While the job is active, PROGRESS may name an immediate Next Chunk. That chunk is only the starting responsibility: validate the actual owner modules, update PROGRESS, commit coherent changes in the owning repository, and continue through remaining mandatory gates.

When PROGRESS is `READY FOR USER LIVE TEST`, there is no implementation Next Chunk. Reopen only from concrete native/regression evidence or an explicit new user goal.

## Repository safety

Work on existing `main` only. Never create branches.

Before writes in any repository, inspect branch/HEAD/status/upstream and preserve unrelated work.

Repository state is never assumed from this document. Recheck all three repositories before any future write, because branch position, ahead/behind counts, and local modifications may change after this job closes.

Never reset, stash, discard, rebase away, or overwrite uncertain work. Treat any future local modification as user/agent-owned until its intent is understood.

## Cross-repository authority discipline

Each change belongs to its canonical owner:

- Core: actor identity, base relationships, shared memories, semantic/conversation mechanisms, capability/extension contracts, persistence/migration primitives.
- Dynamic Trading: trader/commercial/story semantics, trader/guard/settlement facts, radio/trade actions, commercial extension data.
- Project Hoomans: Hoomans-specific dialogue content, social depth, NPC commands, cognition, combat/task/faction/settlement actions and live-body gameplay.

Do not solve coupling by copying the same state or parser into multiple repositories.

## Cross-adopter relationship write safety

Treat Core Social as live canonical state. Do not commit a complete social snapshot reconstructed from an adopter-local cache if another adopter may have changed Core since that cache was produced.

Use Core-owned target identity and bounded mutation/merge APIs. Preserve foreign extensions and memories by construction. Add adversarial interleaving tests whenever a relationship write path changes.

Do not swallow a failed canonical relationship write with `pcall` and continue as though the mutation was durable.

## Migration discipline

Migrations must be versioned, idempotent, non-destructive and retry-safe.

Unknown or inactive adopter extensions are preserved as opaque/dormant payloads. Disabling a mod must not downgrade or erase Core actor/social state.

Never import the same legacy relationship repeatedly on load. Migration must record provenance/version and distinguish migrated, already-migrated, unsupported and conflict states.

## Testing discipline

Prefer source-backed Lua/unit/harness tests using actual production modules.

For each phase run:

- focused owner tests;
- cross-adopter integration tests where affected;
- syntax/Kahlua/static checks for changed runtime Lua;
- relevant existing broad suites;
- `git diff --check`.

Explicitly distinguish synthetic/headless acceptance from native Project Zomboid acceptance.

Synthetic payload preservation is not cross-adopter acceptance. Hot-plug gates must load and exercise the actual production adapters/services for each adopter and interleave their real writes.

Identity hot-plug acceptance must invoke the real Hoomans player-character service (`PNC.PlayerCharacters.EnsureIdentity` / `GetEntityKey`) after a DT/Core-first identity already exists. Manually constructing the expected Hoomans key is not acceptance.

Semantic capability acceptance must exercise `PsychopatzActorConversationService:Submit`, not only direct registry/parser calls. The test must prove effective context capabilities reach parsing.

Dynamic Trading factual whereabouts/story acceptance must assert provenance/evidence from DT/Core world-knowledge state. A hardcoded plausible sentence is not proof of grounded whereabouts.

A deterministic public hash stored in player modData is not authoritative identity issuance proof. Identity-adoption tests must attempt a forged-but-well-formed claim and prove the real Hoomans service rejects it because Core authoritative issuance state does not contain that identity.

For factual DT grounding, test setup must publish/set state through the real upstream DT/Core owner. Passing `destination`, `origin`, `settlement`, or `npcGossip` directly into `TalkService.Submit` may remain a unit test of rendering, but cannot satisfy final production grounding acceptance.

Identity authority tests must exercise Core resolution before Hoomans validation. A mandatory adversarial sequence is: forged/unknown `PNC_CharacterUUID` mirror -> Core/DT `GetTargetKey` or `GetCharacterUUID` -> Hoomans `EnsureIdentity`. The forged UUID must remain unissued and must not become `core_adopted`.

Do not let Core self-register an adopter mirror merely because it is syntactically valid. Hoomans-first registration into Core must be initiated from the validated Hoomans player-character registry/service.

For factual DT travel acceptance, calling `Policy.SetDestinationSettlement` directly is only an API-level test. Final production acceptance must drive the actual excursion/travel lifecycle that owns departure, destination, visit and return transitions.

For player-facing settlement dialogue, tests must use representative machine IDs plus separate human-facing names. Friendly strings used directly as IDs are insufficient because they hide presentation-resolution bugs.

A factual-state persistence gate must perform actual DT storage serialization/reload after setting travel/settlement state and publishing/acquiring knowledge, then re-open TalkService and prove the facts remain available.

Excursion timestamp fields are numeric and may be `0`; never use Lua truthiness to decide whether departure/completion happened. Failure-path acceptance must explicitly cover `departedAt > 0, completedAt = 0`.

For headless trader-record persistence, the persisted storage fixture must be reconstructed from a snapshot/deep copy and the reloaded record must be a distinct object. Reusing the same backing table/object after setting a local variable to nil is not sufficient evidence.

When repository status changes because a formerly uncommitted edit was intentionally committed, update durable docs to describe the actual commit/history. Do not continue claiming the worktree modification is still preserved locally.




No native PZ launch, Workshop upload, republish or destructive save manipulation unless explicitly authorized by the user.

## Performance discipline

No per-tick global semantic scans or actor-wide relationship reconciliation.

Semantic packs register once and evaluate bounded relevant candidates/context. Relationship migration/convergence runs at explicit load/import/actor boundaries, not continuously.

## Documentation discipline

Keep root AGENTS.md unchanged unless a durable repository-wide rule genuinely changes.

This job owns current architecture/roadmap/progress truth. Do not add checked-in GOAL_PROMPT.md; the executable /goal is chat-only.

## Stop conditions

Stop only when:

- all developer-owned mandatory gates are complete and the job is READY FOR USER LIVE TEST;
- a real authorization/scope conflict prevents safe work;
- a concrete unresolvable technical/worktree blocker exists.

Missing user-owned native PZ testing is a handoff gate, not a developer blocker.
