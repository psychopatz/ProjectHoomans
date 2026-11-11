# Unified Semantic Catalog Progress

**Status:** implementation committed locally; unrelated dirty work preserved

**Primary repository:** `/home/psychopatz/Zomboid/Workshop/ProjectHoomans`

**Participants:** PsychopatzCore, DynamicTrading

## Completed in this phase

- PsychopatzCore remains the only semantic CodeBuilder authority.
- Conversation recipes remain self-contained: locale maps live beside their
  phrase, response, choice, and UI records.
- Core content was reorganized into nested domain shards for social scenes,
  social reactions, medical/event reactions, health, knowledge, wellbeing,
  and combat-kill dispositions. Semantic template IDs and locale output are
  unchanged.
- The monolithic bundle source was replaced by
  `conversation/bundles/manifest.json` and 15 owner-validated domain shards.
  Bundle text remains inline and renders to the existing package-owned runtime
  paths for Project Hoomans and Dynamic Trading.
- The Core manifest now recursively discovers nested source roots and validates
  declared auxiliary roots. There is no duplicate harness or compatibility
  bridge.

## Verification

- Core CodeBuilder tests: **86/86 passed**.
- Dynamic Trading tests: **88/88 passed**.
- Affected PNC source/authority/compiler suites: **20/20 passed**.
- PNC-only build: **339 generated files**, 505 phrase families, 56 patterns,
  and 13 UI definitions.
- All-enabled build: **351 generated files**, 505 phrase families, 56 patterns,
  and 21 UI definitions.
- Final PNC-only build contains no Dynamic Trading UI or trader-question
  content.
- Source audit: zero legacy authoring fields, zero locale-split filenames,
  zero hard-size violations, and zero preferred-size violations.
- Full PNC Lua runner: **1016/1018 passed**. The two failures are the known
  unrelated `pnc_population_director_smoke.lua` and custom translation-manager
  smoke assertions; they remain unmodified.

## Commit state

- PsychopatzCore: `c079cbf8cde239f903c057a07c193af7e05ff75f`
- Project Hoomans runtime/tests: `5ad172fe0fe06e7139c1d2030c8232196767aa3a`
- Dynamic Trading: no phase-owned changes were required; prior commit remains
  `77d29f8a9017a4692f9edde5185a6df2f38d81d3`.

Remaining work is limited to the final handoff/checkpoint commit and
verification; future expansions should continue using Core manifests and
external shard declarations.
