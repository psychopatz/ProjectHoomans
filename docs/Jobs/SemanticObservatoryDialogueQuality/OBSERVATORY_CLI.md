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

## Real isolated candidate replay (developer preview)

Only an **existing hand-authored response variant** with runtime-confirmed
registration source, a fresh content fingerprint, and unique manifest-listed
EN/TL translation keys is eligible. Generated registration call sites are
**not** canonical editable owners. No source files are changed by this command.

Add a bounded real-worker case to the proposal above:

```json
{
  "poolID": "semantic.flow.greeting.opening",
  "expectedContentFingerprint": "catalog-v1:REPLACE_WITH_CURRENT_DETAIL_VALUE",
  "variants": [{
    "id": "semantic.flow.greeting.opening.default",
    "EN": "Hey there. Good to see you.",
    "TL": "Uy, mabuti at nakita kita."
  }],
  "case": {"utterance": "hello"}
}
```

```bash
tools/semantic_harness/.venv/bin/python -m tools.semantic_harness --no-gui --jsonl --preview-response-proposal /tmp/greeting-proposal.json
```

The test spawns disposable *actual production Lua workers* for EN and TL;
stages the narrowly patched authored Lua plus the two exact loaded translation
assets in a `TemporaryDirectory` outside PZ watched media; then checks
selected IDs, rendered EN/TL, normalized non-text metadata, action/transport
counts, and source hashes. It emits bounded source/translation diffs and
`approved=false`, `writesToProduction=0`,
`candidateOverlayCleaned=true`. An unchanged, unsupported or ambiguous
candidate **fails closed**. Other gameplay modules and Core still load
from the real checkout. Lua syntax errors and worker failures are surfaced.

The Studio Observatory **Review → Preview proposal file** action uses this
same service. This is not an implicit generation or approval button. Approval,
canonical production edit, fresh worker replay, final SP/MP test and full P7
acceptance remain separate gates.

## Bundled EN/TL grounded fixtures

```bash
tools/semantic_harness/.venv/bin/python -m tools.semantic_harness --no-gui --jsonl --response-quality-matrix tools/semantic_harness/fixtures/observatory_core_en_tl.json
tools/semantic_harness/.venv/bin/python -m tools.semantic_harness --no-gui --jsonl --response-quality-matrix tools/semantic_harness/fixtures/observatory_health_authority_en_tl.json
```

These are two independent 8-case ENGINE-FIXTURE matrices rather than a
single over-cap test. Follow and Stay acknowledgements use the canonical
EN/TL Conversation translation manifest keys; duplicated keys across manifest
files are invalid and cause the actual worker loader to reject startup. These
fixture tests intentionally do not claim full native permission/farewell coverage.

## Join observed turn, verified source and gameplay authority

```bash
tools/semantic_harness/.venv/bin/python -m tools.semantic_harness --no-gui --jsonl --inspect-response-turn "hello"
tools/semantic_harness/.venv/bin/python -m tools.semantic_harness --no-gui --jsonl --inspect-response-turn "follow me"
```

This executes **one** real Lua fixture turn. Each bounded NPC message contains its
actual visible text/translation key and a registration lookup, plus the
Conversation Inspector's action/transport and execution summary. An exact
unique emitted `variant.id` produces `EXACT_EMITTED_VARIANT_ID`. A match only
on `templateID` (e.g. generated Follow) produces
`TEMPLATE_CANDIDATES_ONLY` and **no claimed selected variant ID**. Missing
registration/provenance remains UNKNOWN; plan-turn segments outside the pool
registry cannot be assigned an invented source. This is an *observed* turn, not
a preview/explain, so fixture-allowed gameplay commands may execute within
the isolated worker.

Registration source discovery uses the actual Lua Register/Extend caller. If
the game interpreter does not expose the optional `debug.getinfo` source seam,
the origin is UNKNOWN. Generated automatic registration is labeled a
`GENERATED_REGISTRATION_SITE`, **never** an approved canonical edit source.
For command pools, the loaded automatic flow's responsePool binding and
CapabilityCatalog action registration are traced to the actual action
descriptor caller (e.g. `PNC_SemanticCommandAdapter_CompanionActions.lua`);
the result is exposed as `generatedActionLineage`. This establishes
registered *descriptor* ownership, not arbitrary CodeBuilder reviewed-source
ownership and not permission to patch the generator output.

The production Conversation translation manifests are authoritative for asset
lookup. Companion Follow/Stay default queued EN/TL keys now live in the existing
manifest-listed `GeneratedTaskCommands.json`; contextual/rejected/failed keys
remain in their existing files to prevent cross-file duplicate-key loader
failure. No duplicate translator or generated response compiler was created.


## Lifecycle-negative EN/TL scenario matrix

```bash
tools/semantic_harness/.venv/bin/python -m tools.semantic_harness --no-gui --jsonl --response-quality-matrix tools/semantic_harness/fixtures/observatory_lifecycle_en_tl.json
```

The third independent matrix (8 ENGINE-FIXTURE cases) executes the actual
`conversation.root:menu:goodbye` choice in an opened dialogue and confirms
the returned presentation lifecycle is **closed**, the NPC says “You too.”
or “Ikaw rin.”, and no gameplay actions are dispatched. In contrast a raw
typed `goodbye` outside that root-choice path currently produces
`semantic.ask_clarification` and does **not** close the conversation.
This is observed behavior, not an assertion that every input form is equivalent.
Two cases intentionally retain sequential Follow → Wait history;
they do not establish native mutually-exclusive movement beyond the
worker's accepted request and reply. Simulation → Compare / Regression →
Farewell lifecycle runs the same fixture set through the existing Lua session.

## Production-Lua selection coverage in explicit contexts

```bash
tools/semantic_harness/.venv/bin/python -m tools.semantic_harness --no-gui --jsonl --response-selection-coverage tools/semantic_harness/fixtures/observatory_greeting_selection.json
```

This reads one loaded pool and 1–16 bounded, explicit hypothetical response
contexts. The existing Lua `ExplainSelection` owns eligible/mismatched,
priority/specificity, hash-tie and history decisions. Reports summarize
`eligibleCases`, `selectedCases`, `lowerRankedCases`, `tieCases`, and failed
condition fields with real registry fingerprint/revision. An unselected
variant is **not** declared globally unreachable; all verdicts refer only to
the supplied contexts. Queries do not execute actions or consume selection
history. The same four greeting contexts are runnable from Simulation →
Compare / Regression → Explain selection matrix.

## Verified canonical CodeBuilder lineage (per loaded variant)

```bash
tools/semantic_harness/.venv/bin/python -m tools.semantic_harness --no-gui --jsonl --response-codebuilder-lineage semantic.accept
```

This reuses CodeBuilder's dataset catalog, validated compiler and read-only preview; it compares ID, template, fallback, conditions and priority to the loaded Lua variant. Dialogue sources also require unchanged generated-artifact diffs. Ownership is per variant; mixed pools must not inherit a guessed single owner. Semantic-definition preview does not expose artifact diffs, so that detail is reported as not available. Unmatched or ambiguous variants remain UNKNOWN. Studio → Explore → Responses exposes the same read-only lineage review.

## Optional source SHA pin for isolated candidate previews

A proposal submitted to `--preview-response-proposal` may supply
`expectedSourceSHA256` alongside the existing pool fingerprint. The preview
rejects malformed hashes and stale exact authored-source bytes before staging.
It returns `sourceSHA256`, `translationSourceSHA256` for EN/TL and a
`sourceSHA256GuardMatched` result. An omitted source SHA is allowed for
exploration but must **not** be interpreted as approval for production edits.
The workflow still reports `approved=false`, produces zero production writes,
and requires explicit wording approval and fresh post-approval verification.

## EN/TL command rejection outcome checks

Run the existing --response-quality-matrix CLI with
tools/semantic_harness/fixtures/observatory_permission_rejections_en_tl.json.

This 4-case real-Lua fixture explicitly configures mock network replies for
rejected Follow and Stay requests. It asserts final EN/TL rejection keys, TL
text, commandAccepted=false, executionStatus=rejected, the rejection reason,
and exactly one attempted dispatch/transport. The report labels such replies
CONFIGURED_FIXTURE_NETWORK_REPLY and nativeServerAuthorityVerified=false.
actions counts attempted requests, not successful gameplay effects. This is
not a native or server-side authority/security proof. Unknown expectation
keys now fail instead of silently passing unchecked assertions.

## Packaged Project Zomboid Kahlua syntax verification

Run:
  tools/semantic_harness/.venv/bin/python tools/semantic_harness/kahlua_verifier/verify.py --game-root /path/to/installed/ProjectZomboid/projectzomboid

This invokes the installed game's Kahlua LuaCompiler, not a duplicate compiler.
Temporary Java reflection and generated classes stay outside watched media.
The verifier does not launch PZ, execute Lua, or touch saves. It reports
compiler success/failure as machine-readable JSON. The opt-in integration
test uses the PZ_KAHLUA_GAME_ROOT environment variable.


The expanded eight-case lifecycle fixture additionally tests the real
conversation-root Disband button for a recruited NPC without verified
player-faction authority in EN/TL. The authoritative handler rejects, the
conversation stays open and one attempted transport is recorded. This is a
negative ownership test, not a successful departure or native PZ proof.

## Loaded Lua response and canonical EN/TL manifest ownership

Command: `tools/semantic_harness/.venv/bin/python -m tools.semantic_harness --no-gui --jsonl --response-translation-coverage semantic.question.backstory.ambiguous`

The query joins actual production-Lua variant template IDs to the canonical Conversation EN/TL manifests, retaining exact asset paths and manifest SHA-256. It reports BOTH_MANIFESTED, MISSING_EN, MISSING_TL, NOT_IN_CONVERSATION_MANIFEST and DUPLICATE_MANIFEST_KEY. Not manifested does not imply untranslated dialogue; authored variants may realize through other native or fallback routes. This is static readiness, not runtime fallback or native SP/MP proof. Studio uses the same read-only service.
