# Architecture — one semantic test execution authority

## Ownership
- **Production PsychopatzCore/ProjectHoomans Lua:** sole authority for parsing, candidate selection, flow transitions, response planning, localization, action constraints and effects.
- **Existing Semantic Harness:** sole owner of process/session lifecycle, disposable scenario projection, production module imports, inspection, Observatory and Simulation.
- **Semantic Test subsystem (inside tools/semantic_harness/testing):** schema validation, fixture discovery, expansion, execution coordination, bounded observed-path assertions, reports, selection and provenance.
- **Focused Lua contract tests:** retain low-level imperative coverage, registration semantics, engine boundary mocks, transport and internal contracts; do not invent a JSON scripting language.
- **JSON fixtures:** descriptions of cases only; never executable code, embedded expressions, import directives or arbitrary attribute evaluation.

## Flow
Fixture JSON -> schema/loader -> deterministic case expansion -> isolated ScenarioSession/LuaSemanticWorker -> real production Lua -> canonical bounded observation -> assertion comparator -> compact result/trace, with separate Lua contract tests as complementary coverage.

## Fixture envelope v1
```json
{
  "schema": "pnc.semantic-test.v1",
  "suite": "conversation",
  "id": "conversation.whats_up.basic",
  "tags": ["nlu", "response", "regression"],
  "scenario": {"world": {"weather": "clear"}},
  "turns": [{
    "speaker": "player",
    "text": "What's up?",
    "expect": {
      "ir.subject": {"equals": "CONVERSATION_TOPIC"},
      "ir.extensions.topic": {"equals": "whats_up"},
      "response.exists": true
    }
  }]
}
```
This is an **illustrative target contract**, not proof that currently exposed worker paths exactly match these example paths. P1 must map actual worker outputs and document stable accessor paths before finalizing the schema.

## Constraints
- Schema version and stable case IDs; mandatory validated expected assertions, no silent success on unknown paths. Distinguish ABSENT, null, and unavailable projection; reject unsupported operators.
- Small bounded operators only: equals, notEquals, exists, absent, contains, notContains, prefix, oneOf, min, max, count/minCount/maxCount, truthy/falsy. Reject code/regex/eval and arbitrary Python path expressions by default.
- Explicit scenario defaults and per-case fresh/reset semantics; within-case multi-turn state continuity; no case ordering dependencies.
- Optional bounded table-driven variant and matrix expansion with deterministic IDs, caps and collisions rejected. Language selection must respect existing EN/TL translation paths.
- Canonical projection reuses current Observatory/inspection output; describe the distinction between diagnostic candidate suggestions and native Response Channel choices.
- Tests must inspect realized text, selected template/pool/phrase, IR/flow, choices, action/effect/transport/relationship/storage deltas as relevant, including negative authority assertions. Assert stable semantics, not brittle fixed wording unless text itself is the contract.
- No direct mutation of saves, production registries or source. Read-only previews must not execute actions; isolated execution may mutate only disposable fixture working state.
- CLI/API first and GUI adapter second. Studio/Simulation remain existing public surfaces; no duplicate runner in Studio.
- Tagged/case/suite selection, bounded reports, stable exit codes, failure artifact retention outside watched media, deterministic trace IDs and source provenance.
- Cold/warm performance benchmarks; cache production registration/session where safe but never leak case state. No per-NPC gameplay overhead: development tooling only.
- Remove obsolete runners and converted tests only after measured coverage parity, no compatibility shim or competing entrypoints unless an external caller is proven.
