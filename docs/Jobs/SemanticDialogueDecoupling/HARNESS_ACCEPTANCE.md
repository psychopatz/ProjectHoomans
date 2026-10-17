# Semantic Lab is mandatory — genuine production Lua behavior

`tools/semantic_harness/` loads real production PsychopatzCore/PNC semantic and translation modules via a persistent Lua worker, while mocking Project Zomboid UI/world/server edges. It is the primary headless integration acceptance instrument, **not** proof of native SP/MP.

## Baseline commands (run in actual local checkout)
```bash
tools/semantic_harness/run_harness.sh --doctor --doctor-json
python3 -m unittest tools.semantic_harness.tests.test_semantic_identity_wellbeing_collision -v
python3 -m unittest discover -s tools/semantic_harness/tests -v
tools/semantic_harness/run_harness.sh --test pnc_semantic
python3 tests/run_tests.py pnc_semantic --harness-report /tmp/semantic-decoupling-regression.json
```
Confirm Core dependency SHA, Lua/Python versions and loaded production module manifest. Inspect tests/run_tests.py or suite instructions before adapting commands. A report `conflicts=[]` or passing JSON syntax does NOT establish semantic success.

## Required permanent protected regression
Run ONE persistent worker dialogue: NPC name obligation -> `are you okay` -> NPC reciprocal wellbeing response -> `im fine thanks`; record exact IR, provenance pattern, chosen branch/response and localized text, pending identity lifecycle, `contextBefore`/`contextAfter`, `transport`, `toolCalls`, relationship effects, `llmCalls`, `loadedModules`. Also test:
- `I'm fine, thank you`, `I'm hungry`, a second nearby NPC, unrelated question and explicit identity resumption.
- `My name is Patrick` and `I'm Patrick` (valid true name when profile matches), false explicit name, qualified explicit refusal, and ambiguous context-specific `no`.
- PREVIEW twice versus accepted SUBMIT once, with no duplicate identity or task effects.
- Adversarial new semantic flow overlapping identity/command grammar, and fuzzy unauthorized task/relationship actions.
- EN/TL real response-key and text lookup via instrumented `Translations.lua`; missing TL fallback diagnostics.

## Flow acceptance
Every new/migrated flow must show actual loaded source module, trigger, candidate list/rejected reasons (once available), winner, current node, transition, response key, semantic state changes, and **absence of unintended authoritative request**. Semantic Lab GUI/inspector should display the same values reported by headless worker, not compute its own parallel policy. Authoring must be flow Lua + real module registration; fixtures may be JSON but *never* the implementation itself.

## Translation acceptance
Exact key/value/placeholder parity, EN/TL per-shard ownership, duplicate failure, lazy load behavior through the actual Core manager, language switching and fallback warnings. Run unit and real worker integration tests, not Python-only dictionaries. Any user-facing modification must be checked in both languages.

## Native acceptance
Real game B42 singleplayer and multiplayer (when applicable) must separately establish NPC reply/interaction, server identity/relationship admission, delayed provider events, multi-speaker context, native translation/load/restart, and per-NPC overhead. A present PZ process or a mocked Semantic Lab network result does not close this gate.

## Evidence
For every Next Chunk: exact Hoomans+Core SHAs, scenario IDs, commands, Lua/Python/PZ versions, observed IR and outputs, before/after state/action data, pass/fail/skipped, perf when relevant, native/SP/MP status, and updated PROGRESS. Do not assert 90/90 or 66/66 as freshly rerun without actual output.
