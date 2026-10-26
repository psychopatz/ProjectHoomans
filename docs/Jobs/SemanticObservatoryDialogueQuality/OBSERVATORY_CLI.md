# Observatory CLI — developer preview (production Lua)

This is a **bounded diagnostic entrypoint** inside the existing Semantic Lab
worker. It does not create a second response selector, install a new runtime,
edit saves or publish game assets. All commands run on the existing main checkout.
Use `tools/semantic_harness/.venv/bin/python` from repository root.

## Discover registered pools and inspect real variant records

```bash
tools/semantic_harness/.venv/bin/python -m tools.semantic_harness --no-gui --jsonl --response-pools greeting --response-limit 8
tools/semantic_harness/.venv/bin/python -m tools.semantic_harness --no-gui --jsonl --response-pool semantic.flow.greeting.opening --response-limit 8
```

Results are schemaVersion=1 and include loaded-registry revision, count,
offset/limit, hasMore, real registered IDs, normalized conditions,
priority and **bounded plan summaries**. Source paths and sourceKind are
`UNKNOWN` unless registration supplies verified provenance; that does
not imply these pools are missing. The per-request protocol `id` is a
transport correlation ID, **not** a dialogue variant or source revision.

## Explain why Lua would choose a variant

```bash
printf '%s\n' '{"npcID":"fixture-npc","worldContext":{"weather":{"raining":true}}}' > /tmp/pnc-observatory-rain.json
tools/semantic_harness/.venv/bin/python -m tools.semantic_harness --no-gui --jsonl --explain-response-pool semantic.flow.greeting.opening --response-context-file /tmp/pnc-observatory-rain.json --response-salt morning
```

The context is an explicit **hypothetical fixture projection**. Absent facts stay
unknown. Explain uses the production Lua matcher/score/tie/repeat path,
does **not** consume selection history, dispatch a command, or persist anything.
The separately named internal SAMPLE request *does* consume isolated worker
selection history; it is used only for parity tests.

## Run bounded real-Lua quality matrix

Create a JSON file outside watched PZ `media/` paths:

```json
{"cases":[
 {"label":"EN greeting","language":"EN","utterance":"hello",
  "expected":{"lastKey":"semantic.flow.greeting.opening.question.default","maxActions":0}},
 {"label":"TL greeting","language":"TL","utterance":"hello",
  "expected":{"lastKey":"semantic.flow.greeting.opening.question.default","maxActions":0}},
 {"label":"Follow","language":"EN","utterance":"follow me",
  "expected":{"minActions":1}}
]}
```

```bash
tools/semantic_harness/.venv/bin/python -m tools.semantic_harness --no-gui --jsonl --response-quality-matrix /tmp/response-cases.json
```

Each case starts a **fresh disposable production Lua fixture worker**.
Case rows contain actual visible NPC keys/text, action and transport counts,
language, assertions and PASS/FAIL/OBSERVED_ONLY. Max 8 cases, max 4 intentional
turns per case and 200 chars per utterance; truncation is flagged and
returns nonzero. No assertion means OBSERVED_ONLY, never PASS. Exit 3
indicates an assertion failure or truncated request.

This is **not** proof of native SP/MP, translation completeness, unknown-name
privacy, all pool reachability, CodeBuilder provenance or approved source edits.
For ordinary conversation/authority replay use the existing `--case`,
`--input`, `--audit` and inspector paths. Only actual worker observations
may count toward future developer acceptance.

## Compare saved worker reports without re-running or assuming acceptance

```bash
tools/semantic_harness/.venv/bin/python -m tools.semantic_harness --no-gui --jsonl --compare-response-reports /tmp/baseline-quality.json /tmp/candidate-quality.json
```

Reports must come from bounded `response_quality_matrix` runs. The comparison
lists changed final keys/text/actions/transport, definite expected-assertion
regressions and missing or untested case pairs. A stored-report diff is **not**
proof of an isolated candidate Lua source. Every reported case is explicitly
labeled fixture and retains available checkout SHA/source evidence.

## Preflight a text-only EN/TL proposal without writing sources

Obtain `contentFingerprint` from a fresh `--response-pool` inspection.
Then prepare a JSON proposal **outside `media/`**, for example:

```json
{
  "poolID": "semantic.flow.greeting.opening",
  "expectedContentFingerprint": "catalog-v1:REPLACE_WITH_REAL_VALUE",
  "variants": [{
    "id": "semantic.flow.greeting.opening.default",
    "EN": "Hello there, friend.",
    "TL": "Kumusta, kaibigan."
  }]
}
```

```bash
tools/semantic_harness/.venv/bin/python -m tools.semantic_harness --no-gui --jsonl --review-response-proposal /tmp/greeting-proposal.json
```

This preflight rejects stale fingerprints, unregistered IDs, repeated IDs,
plan/priority/when metadata changes, empty/oversized EN/TL and mismatched
placeholders. It reports reviewable proposed text and retained selection
metadata. **It cannot approve the text**: source ownership remains UNKNOWN
until verified, semantic/translation safety requires review, and actual
source-patched isolation/replay remains P6 work. No files are written, the
worker registry is unchanged and the output records `approved=false` and
`writes=0`. Do not interpret preflight success as authorization to generate.
