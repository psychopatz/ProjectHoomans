# P11B — Health wording-domain characterization

This document records the bounded Health wording slice migrated after P11B0.
It does not move health-state projection, medical facts, gameplay effects,
follow-up state, or medical-bite authority.

## Live ownership before migration

- `PNC_SemanticDialogueLocalResponse_Questions.lua` dispatches
  `NPC_HEALTH_STATE` questions to the fact resolver.
- `PNC_SemanticDialogueLocalResponse_Questions_Facts.lua` reads the existing
  `FactFor` result, maps injured/wounded/critical to
  `semantic.question.health_state.injured`, normal/healthy to
  `semantic.question.health_state.healthy`, and all unsupported or unknown
  values to `semantic.question.health_state.unknown`. It creates a bounded
  `FACT_ANSWER`; known states retain `npc.healthState` as a grounded fact
  reference, while the unknown response remains ungrounded.
- `PNC_SemanticDialogueSituation_State.lua` derives the health fact from the
  live state, bounded body-health snapshot, and HP projection. That authority
  remains unchanged.
- `SemanticCatalog/PNC_SemanticCatalog_QuestionPatterns_ContextQuestions_Health.lua`
  owns the five health question patterns. The existing modular `ui/` source
  owns the `question.health` static suggestion. Neither is wording authority.
- The Health static translation-key map owned three semantic IDs and pointed at
  three `Responses.json` keys. `SpeechRealization/Families/Status.lua` owned
  the three four-style families pointing at twelve `Realizations.json` keys.

## Migrated cohesive domain

Manifest-backed `content/health.json` now owns all three fixed IDs:

- `semantic.question.health_state.injured`;
- `semantic.question.health_state.healthy`;
- `semantic.question.health_state.unknown`.

Each family preserves its neutral, warm, terse, and guarded EN/TL phrase from
the legacy realization catalog. Generated `Health.lua` and EN/TL `Health.json`
are the only runtime/translation wording artifacts. The old static map entries,
three response keys, and twelve realization keys are retired; no aliases were
introduced.

Medical-bite families, parameterized medical/context response pools, health
fact selection, grounded references, and dynamic eligibility/effects remain in
their existing owners for later coherent domains.
