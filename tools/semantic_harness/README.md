# Semantic Lab

Semantic Lab is a portable Python/Tkinter console backed by a persistent Lua
process. The Lua worker loads the real Project Hoomans and PsychopatzCore
semantic modules; only the Project Zomboid engine, conversation session,
relationship store, and network edges are mocked.

The GUI, terminal client, doctor, and automated tests all use the same Python
session backend. Worker requests use a bounded, versioned JSON-lines protocol
with request IDs, a startup handshake, a single serialized request queue,
timeouts, crash detection, and bounded stderr diagnostics.

## Module boundaries

- `app.py` is the stable module and direct-script entry point. It routes doctor,
  CLI, and GUI startup without importing Tk for headless use.
- `cli.py` owns argument parsing, replay, interactive input, and JSONL output.
- `ui/shell.py` owns the asynchronous Tk conversation and future polling. Its
  **Turn facts** tab shows the worker's bounded production observation
  (selected candidate, rendered NPC response, active/suspended flow nodes,
  translation lookups, and observed side effects); **Raw worker record** keeps
  the complete bounded response for deeper inspection. **Preview** calls the
  production router without recording a turn or dispatching an action.
- `ui/flow_editor/` owns the **Flow editor** tab's graph model and visual form.
  It reads normalized definitions from the production Lua registry, draws
  nodes/edges and selected response pools, and sends draft validation and
  registration back through the same Lua worker (`Registry.Validate` and
  `Registry.Register`). It is an authoring surface, not a second Python flow
  engine.
- `studio/workflow.py` owns the **Build workflow** tab inside the same Semantic Lab.
  It selects an existing canonical dataset, composes reusable block contracts,
  validates the selection, previews the existing CodeBuilder artifacts, and
  requires explicit approval before generation. Generation delegates to the
  existing writer; the GUI then restarts the same Lua worker and returns to
  the Simulation tab for real-worker inspection.
- `runtime/` owns the Python/Lua boundary: configuration discovery, the
  editable scenario document, the versioned JSON-lines protocol, child-process
  lifecycle, the worker adapter, and serialized worker sessions. Runtime
  modules are imported from their owning `runtime/` subpackage.
- `codebuilder/` owns the canonical typed interaction source, reusable
  CodeBlocks, compiler/build adapters, approved artifact authoring operations,
  and the pure production interaction-catalog projection used by the service.
  CodeBuilder modules are imported directly from their owning subpackages;
  there is one compiler and one artifact writer.
- `studio/` owns the Semantic Lab authoring surface: canonical dataset and
  reusable-block panes, typed interaction composition, and workflow
  orchestration. It delegates compilation, generation, and catalog projection
  to CodeBuilder rather than owning a second compiler or authoring service.
- `inspection/` owns bounded worker-result projections, the Conversation
  Inspector chain, CLI/JSON presentation, and the visible transcript buffer.
  It does not interpret dialogue or dispatch gameplay effects.
- `ui/dialogs/settings.py` renders the worker-provided simulation control
  catalog, collects typed edits into one scenario draft, and validates it
  before the live worker is configured.
- `testing/runner.py` owns case replay and its streaming conflict ledger;
  `testing/suite.py` owns isolated Lua smoke-test subprocesses;
  `testing/doctor.py` owns bounded environment/worker diagnostics; and
  `testing/performance.py` owns protocol evidence. Testing modules are
  imported from their owning `testing/` subpackage.

Python owns the editable scenario and child-process lifecycle. The isolated Lua
worker owns only its current in-memory production-module state. Native action
and network boundaries remain mocked by the harness.

The GUI keeps at most 200 transcript entries, 200,000 characters total, and
8,192 characters per entry. Interactive `--audit` retains at most 4,096 event
IDs (256 characters each) and 256 conflict records; an `audit_truncated`
record marks an incomplete audit so a cap cannot look like a clean result.
`--fail-fast` cancels queued smoke tests and terminates other active test
processes.

The repository Lua smoke runner also uses the bounded suite adapter by default.
It keeps one Lua process per test, caps captured output, records process
lifecycles and PIDs, reports timeouts, and detects concurrent duplicate test
execution. Use `--legacy-runner` on `tests/run_tests.py` only when comparing
against the previous subprocess implementation.

The worker loads the production translation bootstrap and conversation tool
reply catalog from the checked-out mod/Core files. Each turn exposes the raw
Lua module manifest, translation lookups, transport records, and normalized
tool/action calls (`ask_name`, `validate_identity`, `adjust_relationship`,
`companion_command`). Friendly labels are diagnostic only; the raw production
command remains beside them.

Turn and preview responses also include a bounded `observation` object built by
the Lua worker from the production result. It is the GUI's shared inspection
contract: `ir`, `candidates`, `response`, `flow.activeBefore`/
`flow.activeAfter`, `translation`, and `sideEffects`. It does not infer a
second Python response or policy engine.

The **Flow editor** tab is the practical authoring loop for registered flows:
select a production flow to browse its graph, click a node to edit its response
pool/template, terminal flag, accepted frames, or transition targets, and edit
the flow ID/owner/initial node/trigger frames above the graph. **Validate draft**
calls the production registry validator; **Register draft** adds a new valid
definition to this worker so the next conversation turn can exercise it.
**Save draft** and **Open draft** persist the bounded definition for review.
Registration is worker-local and disappears when that worker is restarted; it
does not write a Workshop package or alter the checked-out Lua source.

## Package entrypoint

The application can be invoked directly without the shell launcher:

```bash
python3 -m tools.semantic_harness --help
```

The repository metadata exposes the same existing entrypoint as
`semantic-lab` in an editable/development installation.

## Launching

The portable launcher creates and reuses `tools/semantic_harness/.venv`:

```bash
tools/semantic_harness/run_harness.sh
```

Run headlessly from any directory:

```bash
/home/psychopatz/Zomboid/Workshop/ProjectHoomans/tools/semantic_harness/run_harness.sh \
  --no-gui --jsonl \
  --scenario tools/semantic_harness/scenarios/identity_exchange.json \
  --input "what is your name" \
  --input "I'm Patrick"
```

Use one input per stdin line for terminal conversations:

```bash
tools/semantic_harness/run_harness.sh --no-gui --interactive --jsonl
```

Select Tagalog at startup, or change the language from the GUI while the
worker is alive:

```bash
tools/semantic_harness/run_harness.sh --no-gui --jsonl --language TL \
  --input "what is your name" --input "I'm Patrick"
```

Replay a reusable case and run the conflict ledger:

```bash
tools/semantic_harness/run_harness.sh --cli --jsonl \
  --case tools/semantic_harness/scenarios/identity_exchange_case.json
```

For ad-hoc inputs, append `--audit` to emit a final bounded conflict record.
The GUI also exposes a worker restart action that restores the current
scenario after a timeout or child-process failure.

Common world, NPC, persona, relationship, bond, health/activity, role, language,
and integration values are edited from typed controls in **Simulation
settings…** and saved with **Apply & Save** or **Save scenario**. Needs and
persona dimensions are bounded sliders, finite fields use worker-catalog
comboboxes, and counters/time use numeric controls. Player and NPC inventories
default to a structured editor with search over the installed Project Zomboid
`media/scripts` definitions, add/remove, stack, condition, container/location,
and equipment controls. Each inventory also has an **Advanced JSON** tab over
the same draft; unknown fields are preserved across round trips. Item-carried
MarketSense/classification metadata is displayed read-only when present. The
dialog also covers player/NPC identity, conversation, network/runtime flags,
mocked native action responses, and translation overrides. It edits one draft
and configures the live Lua worker only after validation. Scenario files are
the harness's portable JSON data store;
`save_scenario` writes them atomically so the same values can be loaded by the
GUI, terminal client, and tests.

The underlying scenario JSON remains easy to version and extend under
`world`, `npc`, `player`, `conversation`, and `runtime`. In particular,
`runtime.nativeTranslations` adds explicit test-only catalog overrides and
`runtime.commandResponses` controls the mocked native action boundary; a camp
admission can provide `accepted`, `reason`, and `details.siteLabel` without
changing production Lua. The engine seam stays configurable while the parser,
policy, identity authority, translation manager, and tool-reply catalog remain
real.

## Inline simulation workbench

The Simulation tab exposes a collapsible workbench for the worker-catalog fields most often tuned during dialogue tests: NPC profile/role, bond, directed standing, social style/personality, health/activity, common needs, language, and the Dynamic Trading adapter. These controls and the full **Simulation settings…** dialog edit one scenario draft. **Apply** configures the real Lua worker; **Apply + replay** applies the draft and reruns the current input, or the most recently submitted test utterance, through the normal worker input path. Neither action simulates semantic results in Python.

## Per-NPC semantic wellbeing scenarios

An editable scenario can set `npc.healthState`, `npc.activeBehavior`,
`npc.needs` (hunger/thirst/fatigue), and `npc.conditionStats`
(stress/boredom/panic). These fields are projected to the production Lua
dialogue situation. If a dedicated NPC state table is absent, legacy
`world` values continue to provide mock needs/conditions. An explicit
empty table means the NPC fact is unknown; setting health/activity to
`null` also removes the default assumption in the worker.

Turn output includes `routedSituation`, read from the actual production
semantic router after input submission. Inspect its `npc` fields alongside
the returned IR, decision, message payloads, `contextBefore`/
`contextAfter`, transport, and `llmCalls`. The case replay conflict
ledger is **not** a semantic-reaction assertion.

The persistent worker also exposes a `PREVIEW` command through
`LuaSemanticWorker.preview(text)`. It runs the production router's
parse/resolve/decision path without recording a turn, queueing a response,
dispatching an action, or calling a provider; repeated previews are suitable
for checking idempotence before submission.

The production-worker tests for these scenarios are:

```bash
python3 -m unittest tools.semantic_harness.tests.test_wellbeing_projection -v
```

Refer to `docs/Jobs/ContextualSemanticIntelligence/HARNESS_ACCEPTANCE.md`
for the complete acceptance matrix and real-game limitations.

## Diagnostics

Run this before debugging a startup problem:

```bash
tools/semantic_harness/run_harness.sh --doctor
tools/semantic_harness/run_harness.sh --doctor --doctor-json
```

The doctor checks Python/venv, Tk availability, display availability, Lua
discovery/version, worker syntax, repository paths, and the real worker
`READY`/`PING`/`CAPABILITIES` handshake. Set `PNC_HARNESS_LUA` when Lua is not
on `PATH`, and set `PNC_HARNESS_CORE_REPOSITORY` when the core checkout is not
next to Project Hoomans.

Python venv isolation does not bundle Lua. The launcher therefore discovers an
explicit Lua executable or reports a bounded actionable error; it does not
silently replace deterministic Lua semantics with an LLM.

To save the smoke-suite lifecycle/conflict report:

```bash
python3 tests/run_tests.py pnc_semantic --harness-report /tmp/semantic-suite.json
```

The same test path can be launched through the harness venv:

```bash
tools/semantic_harness/run_harness.sh --test pnc_semantic
```

## Testing

```bash
python3 -m unittest discover -s tools/semantic_harness/tests -v
tools/semantic_harness/run_harness.sh --test pnc_semantic
```

The tests cover entry-point routing, headless CLI imports, settings validation,
bounded transcript and conflict history, fail-fast process termination, real
production semantic modules, authoritative character identity, false names,
pronoun/self-directed language, trait-aware responses, editable inventory
queries, gift transfer effects, JSON request correlation, concurrent caller
serialization, and worker timeout termination.

The worker intentionally loads a narrow semantic dependency closure rather
than the complete Project Zomboid composition root. This keeps failures
diagnosable and keeps native-only UI/world APIs behind explicit mocks. A real
game smoke test remains required for native UI, Java objects, and live network
behavior.
