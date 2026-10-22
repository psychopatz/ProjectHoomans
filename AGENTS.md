> **ACTIVE CONTEXTUAL DIALOGUE PERSONA & CHOICES GOAL (2026-10-23 P11):** The current approved product goal is `docs/Jobs/ContextualDialoguePersonaChoices/`. P10 contextual-hub/control/inventory infrastructure is retained, but the P10 READY FOR USER LIVE TEST handoff is superseded by the post-P10 runtime-parity audit. Read this root policy, then that job's `README.md` -> `AGENT_RUNBOOK.md` -> `AUDIT.md` -> `ARCHITECTURE.md` -> `BEHAVIORAL_COMPLETION.md` -> `SEMANTIC_LAB_CONVERSATION_VISUALIZATION.md` -> `SEMANTIC_SIMULATION_UX_AND_CONTEXTUAL_HUB.md` -> `RUNTIME_PARITY_ACTORS_RELATIONSHIPS_AND_UX.md` -> `ROADMAP.md` -> `HARNESS_ACCEPTANCE.md` -> `PROGRESS.md` last. Current mandatory phase is P11A: make Player/NPC/Relationship/World first-class in the Simulation workbench, remove hypothetical normal bond kinds, and relocate developer-only toolbar clutter without deleting capabilities. Then continue autonomously P11B-P11H: first-class Player/NPC needs and real traits/generated personality, automatic durable friend promotion, compatibility + player proposal + server-authoritative lover acceptance, relationship preview/Compare cleanup, unified Flow/Hub/ConversationBlock runtime graph, modular realization packs, and final usability regression. Family is authored/pre-existing; friend is earned; lover requires proposal + acceptance using existing gender/orientation/trait compatibility. Existing `main` only, no new branch, no checked-in `GOAL_PROMPT.md`, no native Project Zomboid or Workshop action by the agent.

> **ACTIVE CROSS-MOD PORTABLE CONVERSATION GOAL (2026-10-21):** PsychopatzCore `Docs/portable_npc_conversation/` owns C1–C6, with Hoomans integration contract `docs/Jobs/ContextualDialogueQuestFramework/CORE_CONVERSATION_ADOPTION.md`. Hoomans V1–V5 developer work and PR #4 merge already occurred. Do NOT replay old unmerged-branch/bootstrap/V1-current instructions found below; they are historical. Read Core's `PROGRESS.md` LAST and continue one safe chunk at a time through all C phases. Never create a branch or a checked-in /goal prompt, and never perform native PZ or Workshop actions.

> **Current active Semantic Lab job override (2026-10-20):** ProjectHoomans `main` already contains the former B0–B6/H0–H4/F1–F4 implementation and prior PR #4 is MERGED. Any older paragraphs below claiming that PR #4 is unmerged/CodeBuilder source lives only on an old branch are OBSOLETE and must not trigger a merge/rebase/pull. Approved new product goal is `docs/Jobs/ContextualDialogueQuestFramework/V1_V5_VISUAL_AUTHORING_AND_RUNTIME_CONSOLIDATION.md`; `PROGRESS.md` current V1 execution chunk, then autonomously through V5. **No new Git branches**, new work on safely-checked existing `main` only, **no checked-in GOAL_PROMPT.md**, no native PZ/Workshop action by Codex.

# Project Hoomans working rules

## Project Zomboid mod layout

- Treat `Contents/mods/ProjectHoomans/42.20/` as the current
  Project Zomboid runtime layer. Executable Lua, lifecycle services, UI
  integrations, registries, and engine/API adapters belong under its `media/`
  tree.
- Treat `Contents/mods/ProjectHoomans/common/` as version-agnostic packaged
  content. Keep reusable declarative definitions, translations, animations,
  clothing, sounds, textures, and similar shared assets under its `media/`
  tree.
- Keep Build 42 JSON translations at
  `common/media/lua/shared/Translate/<LANG>/*.json`. Do not create a
  repository-root translation source tree outside the Project Zomboid mod.

- Do not use `pcall` or `xpcall` for normal control flow, input validation, or
  engine-bug workarounds. Prefer explicit guards and direct fixes.
- Use a protected call only when an external or addon-owned callback is an
  unavoidable failure boundary after ordinary validation, and document that
  reason beside the call.

## Never stage a write through a temporary directory under `media/`

Project Zomboid recursively watches every loaded mod's `media/` tree with
`DebugFileWatcher`. On a directory `ENTRY_CREATE` it walks that directory; if
the directory is already gone it logs `NoSuchFileException`, sets its internal
`WatchService` to `null`, and every later `update()` throws
`NullPointerException: ... "this.watcher" is null` for the rest of the session.
The engine never re-initializes the watcher, so mod hot-reload stays dead until
the game is restarted.

- While `ProjectZomboid64`/`ProjectZomboid` is running, only write or replace
  files under `Contents/mods/**/media/` in ways that create a *file* or rename
  a file into place.
- Never create a staging *directory* inside a watched `media/` tree, e.g.
  `.Foo.lua.<pid>.<uuid>.tmpdir` next to the target file. Such a directory
  lives for about a millisecond and is exactly what trips the engine.
- `git checkout`, `git stash`, `rsync`, `unzip`, and tooling that stages
  directory swaps (agent file writers, sync tools) are the same hazard.
- If a staging directory is required, keep it outside `media/`, or stop
  Project Zomboid first. Restarting the game is the only way to re-arm the
  watcher.

## No-new-branches and safe main integration (user rule, 2026-10-20)

**NEVER CREATE A NEW GIT BRANCH** for implementation, test, audit, documentation, agent work or pull request. Do not use `git checkout -b`, `git switch -c`, `git branch <new>`, a scratch worktree branch, or agent automatic branch creation. This rule also applies when coordinating PsychopatzCore and DynamicTrading.

For new authorized work use **existing `main`**, after checking local and remote HEAD/upstream and concurrent changes. Do not assume existing PR history is present in main. As of 2026-10-20, existing `docs/contextual-dialogue-quest-framework-20261018` branch / PR #4 is 144 commits ahead and 1 behind main; preserve it and reconcile safely using `fetch`/`merge-base`/`merge-tree`/source diff, then merge onto existing main only when conflicts, dependencies and tests are resolved. No new integration branch, blind pull, force push, destructive reset/rebase/stash or overwritten agent/user work. If safe integration cannot be proven, report the precise conflict and continue independent work on an already existing checked-out ref; do NOT create another branch.

Root `AGENTS.md` is durable policy, not authority to publish Steam Workshop content or launch native Project Zomboid. For the ongoing personal NPC dialogue/backstory goal, detailed documentation currently lives on the **preexisting** Hoomans PR #4 branch at `docs/Jobs/ContextualDialogueQuestFramework/`. Full developer B0–B6 acceptance, not a passing B0 subphase, determines the parent goal handoff. Review that goal's `GIT_INTEGRATION_AND_NO_NEW_BRANCHES.md` before any integration.

## Active Semantic Lab goal and chat-only /goal policy (2026-10-20)

For `docs/Jobs/ContextualDialogueQuestFramework/`, the current canonical goal documentation is on **existing main**. The prior B0–B6 implementation history remains on an already-existing divergent development branch and is NOT yet integrated into main. Preserve all code. Review the job's `PROGRESS.md`, `ROADMAP.md`, `AGENT_RUNBOOK.md`, `HARNESS_FIRST_CODEBUILDER_TRANSLATION_RECOVERY.md`, and `GIT_INTEGRATION_AND_NO_NEW_BRANCHES.md`. No new Git branches; do not continue writing new feature commits to the old branch as a workaround. If safe in-place reconciliation cannot be proven, report exact conflicts rather than force/pull/rebase/reset.

**Do not create or update a checked-in `GOAL_PROMPT.md` or store the full assistant-provided `/goal` invocation in any repository document.** User wants goal prompts delivered in ChatGPT only. Durable docs contain architecture, acceptance, next chunk, rules and source evidence; bootstrap prompt is conversational only.

The current product assignment is **complete harness-first grounded personal dialogue**: existing CodeBuilder emits production Lua and EN/TL catalog assets, real Semantic Lab Lua worker runs meaningful end-to-end conversation scenarios, all NPC fact/disclosure/dossier/PBrainZ outputs remain server-authorized, and translations use existing PsychopatzCore CustomTranslationManager and ProjectHoomans registrations. B0–B6 ledger acceptance is historical developer evidence, not acceptance of this new full tool/translation/integration gate. Work one safe chunk at a time but continue automatically through all mandatory corrective phases before reporting developer READY FOR USER LIVE TEST.
