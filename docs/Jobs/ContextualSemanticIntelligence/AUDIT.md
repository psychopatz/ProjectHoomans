# Final pre-implementation audit — 2026-10-17

## Revision and evidence scope

Source inspected via connected GitHub for `psychopatz/ProjectHoomans` main at `c96cadda1570f59810552f9d3fc55d5c957ba670` (last commit 2026-10-14); `psychopatz/psychopatzCore` main `efac85a182c86fdb07e7da7ccd693e1a6e66ccc6`; `psychopatz/PBrainZ` main `43cc879e673d8d0494d7e77b4ade28fd20a6d4c4`. Reference: `VideoGameSmash12/Facade` master, especially `TemplateCompiler/Preprocessor.java`, `NLU.java`, `WordNet.java`, `ASTTemplate.java`, and `nlu/reaction/ReactionDecider.java`.

**Evidence classification:** Static source and test inspection only. No local Project Hoomans checkout, Lua runtime, Project Zomboid game session or exact-HEAD Semantic Lab execution was available during this audit. The repository GitHub Actions runs collection returned no workflow runs; do not infer CI success or failure. Remote HEAD is not evidence about a developer's local worktree. Previous scores or test totals in `docs/Systems/Semantics.md` are historical, not fresh acceptance.

## Source-verified implemented foundation — preserve it

- PsychopatzCore normalizes input, tokenizes bounded text, registers concepts and patterns, performs exact-first/fuzzy-optional matching, and emits validated semantic IR. `PsychopatzSemanticParser.lua`, `PsychopatzSemanticPatternMatcher_Rules.lua`, `PsychopatzSemanticConfidence.lua`, `PsychopatzSemanticDialogueRouter.lua`.
- Project Hoomans routes recognized intents through `PNC_SemanticDialoguePolicy_IntentBranch.lua` and `PNC_SemanticDialoguePolicy_Flow.lua`. Low confidence, unresolved references and fuzzy action safety already have specific guards.
- `PNC_SemanticDialogueSituation_Core.lua` and `_State.lua` derive bounded NPC activity, needs, health, emotions and social state. Project Hoomans' `PNC_SemanticDialogueReferenceResolver.lua` handles bounded mentions and pronouns.
- `PNC_SemanticDialogueResponseCatalog.lua` already matches scalar contextual conditions (needType, needUrgency, healthState, socialStyle, emotionType, relationshipState, hostilityCount, etc.), scores variants by priority/specificity and avoids consecutive repeated variants. Do **not** add another text-variant selector.
- `PNC_SemanticDialogueContextState.lua` and `_Turns.lua` preserve bounded turns, mentions, current/previous topic, last intent and a pending identity obligation. Core DialogueState already has pending-request behavior. Do **not** add a parallel transcript store.
- `tools/semantic_harness/codebuilder/sources/` already compiles *reviewed* WordNet 3.0 verb senses/forms offline and compiled authored interactions; avoids copying unreviewed text or shipping WordNet data into runtime.
- `tests/pnc_semantic_state_response_smoke.lua`, `pnc_semantic_social_chat_smoke.lua`, `pnc_semantic_gift_followup_smoke.lua`, `pnc_semantic_situation_smoke.lua` and `pnc_semantic_local_route_smoke.lua` already exercise useful aspects of continuity, context and authority.
- PBrainZ has optional provider orchestration, bounded retrieval and semantic tool-call normalization; it is not required for the deterministic branch.

## Semantic Lab — verified real infrastructure

`tools/semantic_harness/README.md` documents a persistent Lua worker running real production semantic modules, with Python/Tk/CLI shell, versioned JSON-lines protocol, timeouts, isolated Lua smoke runner, editable scenario fixtures, conversation transcript, tool/action trace and conflict ledger. `lua/worker/ProductionModules.lua` loads the production Core parser, Hoomans catalog/policy/input and selected identity/authority modules; native UI/network boundaries are mocked. `lua/worker/Conversation.lua` calls real `PNC.Semantics.DialogueInput.Submit(view, text)` and returns IR, decision, messages, trace, transport, relationship/context before-after, loaded modules and LLM count.

## Critical uncovered/bounded gaps

1. **Harness projection is insufficient for wellbeing acceptance.** In `lua/worker/Conversation.lua`, `entry.snapshot.healthState` is hard-coded `"healthy"`, `activeBehavior` is hard-coded `"idle"`, and needs/conditions derive from `scenario.world`. An editable `npc.healthState` or `npc.activeBehavior` would currently not be reflected in those snapshot fields. Verify actual production context ownership and add scenario projection narrowly. Missing values must remain unknown where production semantics require unknown, not become fabricated health.
2. **Harness's replay conflict ledger does not assert reaction correctness.** `runner.py` `run_case` records turns and checks ordering/duplicate authoritative event conflicts; `cli.py` exits nonzero for reported conflicts. Empty conflicts means *no detected protocol conflicts*, **not** correct response meaning. Add explicit assertions against the real worker's IR/decision/response/continuity and absence of side effects using existing Python unittest harness or focused Lua smoke tests.
3. **General situation-dependent reaction arbitration remains unproven.** `PNC_SemanticDialoguePolicy_IntentBranch.lua` chooses high-level branch from IR, while `PNC_SemanticDialogueResponseCatalog.lua` chooses conditioned text. A distinct conversation *behavior* change based on competing contextual reactions is not yet demonstrated. First prove the missing wellbeing vertical slice; extend the existing policy only if data-conditioned catalog variants cannot solve it.
4. **Dialogue continuity has implemented special cases, not verified general coverage.** Identity obligations, pending requests and item references exist. General wellbeing disclosure followed by "What's wrong?" and "Can I help?" needs a real-worker trace and specific state/response assertions.
5. **Real PZ runtime acceptance is outstanding.** The harness mocks native UI, world objects, network edges and parts of relationship/session storage. It cannot prove Java, live UI, real authority, live SP/MP behavior, or offscreen NPC scaling.

## Failure modes to prevent

- Adding phrases but not verifying that a recognized utterance reaches a production reply.
- Calling a replay fixture passing merely because the output is valid JSON or no duplicate event was seen.
- Hard-coding a canned response for a test without real situation/context injection.
- Marking mock server transport as real multiplayer acceptance.
- Losing pending obligations by changing preview/accepted-turn ordering.
- False factual assertions ("injured" or injury cause) from absent snapshot evidence.
- Incorrect command execution due to fuzzy/follow-up pattern reuse.

## Audit verdict

**Proceed with a harness-grounded baseline/projection chunk, not a Jess rewrite and not a new standalone dialogue framework.** Implementation and game runtime acceptance are **not started** for this job. Phase 0 is mandatory.
