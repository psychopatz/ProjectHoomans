# Contextual Semantic Suggestions
Status: DEVELOPER-SIDE COMPLETE — semantic-first root presentation implemented and validated. Native Project Zomboid SP/MP acceptance remains UNTESTED and user-owned. Hoomans commit: `a390bdb0`; Core dependency commit: `ba60095`.
## Goal
After typed player input and after NPC dialogue, provide helpful, localized contextual suggestion buttons. Buttons carry canonical semantic frames, obey declarative eligibility/visibility rules, and enter the **existing** authoritative conversation/action pipeline. The same behavior must be inspectable and clickable in the **existing** Semantic Lab against real production Lua.
Read: AGENT_RUNBOOK.md, PROGRESS.md, ARCHITECTURE.md, ROADMAP.md, HARNESS_ACCEPTANCE.md, GOAL_PROMPT.md.
Related existing owners: ../ContextualDialogueQuestFramework/ (authoring, flows, CodeBuilder, harness), ../SemanticDialogueDecoupling/ (parser/policy and EN/TL), ../CoreNPCFoundationMigration/ (Core actor state), ../ContextualSemanticIntelligence/ (wellbeing and context). Existing job scopes remain intact; do not create parallel implementations.

## Implemented surface

The existing production conversation root is now projected into the semantic suggestion surface. Root categories, identity choices, system choices, and owned-companion choices carry typed route metadata and remain backed by their original production closures. Semantic clicks resolve back through the existing conversation/action pipeline; they do not execute projected callbacks or create a second dialogue state owner.

The Semantic Lab worker and Tk Simulation tab expose the initial root projection, topic/action/utility groups, EN/TL labels, predicate traces, editable NPC profiles, real root-to-block transitions, and stale/duplicate click results. The native Hoomans definition hides the generic Core visual choice part while retaining it as an internal compatibility channel through the new generic Core visibility seam.

Validation and handoff evidence are maintained in [PROGRESS.md](PROGRESS.md) and [HARNESS_ACCEPTANCE.md](HARNESS_ACCEPTANCE.md). No push, Workshop publication, or release action was performed.
