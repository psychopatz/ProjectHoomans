# /goal — Contextual Semantic Suggestions

```text
/goal
Repository: /home/psychopatz/Zomboid/Workshop/ProjectHoomans (verify actual checkout before work).
Dependency: /home/psychopatz/Zomboid/Workshop/psychopatzCore (verify actual checkout; never assume its revision).
Branch: existing main only. No new branch or unauthorized release.

Full objective: Implement contextual, constraint-governed semantic dialogue suggestion buttons for both typed player input and NPC replies, with explicit canonical semantic click actions, EN/TL localization, privacy-safe visibility, and full inspection/interaction through the existing production-Lua Semantic Lab GUI/worker. This is a complete multi-phase assignment, not a single audit or one test case.

Read in order:
1. docs/Jobs/ContextualSemanticSuggestions/AGENT_RUNBOOK.md
2. docs/Jobs/ContextualSemanticSuggestions/PROGRESS.md
3. docs/Jobs/ContextualSemanticSuggestions/ARCHITECTURE.md
4. docs/Jobs/ContextualSemanticSuggestions/ROADMAP.md
5. docs/Jobs/ContextualSemanticSuggestions/HARNESS_ACCEPTANCE.md
6. docs/Jobs/ContextualDialogueQuestFramework/ARCHITECTURE.md and CAPABILITY_ACTION_BINDINGS.md
7. docs/Jobs/SemanticDialogueDecoupling/ARCHITECTURE.md and translation/authority contracts

Starting phase: S0. First chunk: audit real dialogue client input/reply UI, canonical semantic frames and response plans, active flow state, Core actor/relationship/public query contracts, existing action dispatcher, existing Semantic Lab Lua worker and Tk editor/inspector. Reproduce before-state in actual worker and document exact reusable seams. Then implement S1–S6 in order, verifying and recording evidence after each coherent slice. Continue autonomously until the complete developer-side goal is complete.

Non-negotiables: PsychopatzCore owns only reusable generic mechanisms; ProjectHoomans owns gameplay policy. No second parser, response generator, semantic harness, Tk app, translation backend or state owner. Do not create scratch JSON instead of production Lua/UI. Keep suggestion generation non-executing, click frames typed, effects server-authoritative, preflight and click-time eligibility separate, requests replay/stale safe, and existing handlers the ONLY side-effect owners. Use declarative typed all/any/not predicates, fail closed for unknown/private fields, do not infer romance compatibility/consent from one orientation trait; hide secret/undiscovered/private conditions from player-facing views. Preserve EN/TL translation manager and existing PBrainZ/abstract-mode compatibility.

The existing Semantic Lab GUI and production Lua worker are MANDATORY validation tools. Demonstrate visual buttons, editable scenarios, predicate trace, localization and real click-to-dialogue/action transitions; no synthetic JSON-only or unit-test-only closure. Check follow/stay/wait-at, wellbeing, identity, knowledge privacy, relationship boundary values, traits, hostile/busy NPCs, orientation compatibility/consent, stale and duplicate click, and no unauthorized side effects. Run relevant Python/Lua regressions, doctor, Kahlua, bounded perf checks and fix regressions.

On each phase: update the job PROGRESS with source SHA, exact tests, observed GUI/worker results, failures and next phase; commit cohesive changes safely to existing main only after checking user work and remote state. Do not stop simply because a phase passed. Stop only for a real safety/authorization blocker or when all developer-side gates pass. Native PZ SP/MP live test is reserved for the user; report it UNTESTED and hand off as READY FOR USER LIVE TEST. Never install, publish, or republish anything to Steam Workshop or request Workshop authorization as a workaround. No release action.
```
