# Semantic Lab

Semantic Lab is a portable Python/Tkinter console backed by a persistent Lua
process. The Lua worker loads the real Project Hoomans and PsychopatzCore
semantic modules; only the Project Zomboid engine, conversation session,
relationship store, and network edges are mocked.

The GUI, terminal client, doctor, and automated tests all use the same Python
session backend. Worker requests use a bounded, versioned JSON-lines protocol
with request IDs, a startup handshake, a single serialized request queue,
timeouts, crash detection, and bounded stderr diagnostics.

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

Runtime mock values can be edited from the GUI's **Mock runtime…** modal and
saved with **Save scenario** or **Apply & Save**. The **Inventories** tab is the
player/NPC inventory editor: it accepts the full JSON projection, including
item IDs, full types, display names, stack counts, condition/state fields,
containers/equipment, and MarketSense classification. This is the data used by
semantic inventory queries and gift selection, so adding an Apple or changing
the NPC's seafood stock immediately changes the conversation result.

The modal also covers the player, NPC, relationship, world, conversation,
network/runtime flags, mocked native action responses, and translation
overrides. It edits a draft first, then configures the live Lua worker only
after validation. Scenario files are the harness's portable JSON data store;
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
python3 -m unittest tools.semantic_harness.tests.test_harness -v
```

The tests cover real production semantic modules, authoritative character
identity, false names, pronoun/self-directed language, trait-aware responses,
editable inventory queries, gift transfer effects, JSON request correlation,
concurrent caller serialization, and worker timeout termination.

The worker intentionally loads a narrow semantic dependency closure rather
than the complete Project Zomboid composition root. This keeps failures
diagnosable and keeps native-only UI/world APIs behind explicit mocks. A real
game smoke test remains required for native UI, Java objects, and live network
behavior.
