# Contextual Dialogue & Quest Framework — Current Progress

**Updated:** 2026-10-21
**Parent goal:** DEVELOPER COMPLETE — V1–V5 verified on the existing `main` branch; READY FOR USER LIVE TEST
**Documentation baseline:** `556bdd7a57a7`
**Repository rule:** no branch was created; native Project Zomboid SP/MP, live servers, installation, and Workshop publishing remain user-owned.

## Preserved foundation

B0–B6, H0–H4, and F1–F4 remain the preserved implementation baseline. The work continues through the existing Semantic Lab, `semantic.interaction_spec.v1`, CodeBuilder, Core-backed translation path, server-authoritative Knowledge/Dossier services, Lua worker, and Conversation Inspector. The historical F1–F4 ledger is evidence, not a replacement for the V1–V5 requirements.

## Semantic Harness modularization audit

**Status:** completed behavior-preserving refactor on existing `main`; no branch created. The compiler, authoring service, and Flow Editor now use focused implementation modules behind their established compatibility facades. Commits: `13264b40`, `400072d1`, `c500602e`, `84f179fb`, `6fdf0470`, `67e801f6`, `c258fd76`, `e286c3b2`, `68919d5c`.

The final architecture scan improved scoped harness health from `86.4` to `90.2`, reduced findings from `43` to `41`, removed the `LARGE_MODULE` finding, reduced CodeBuilder pressure from `20.3` to `18.9`, and reduced Flow Editor pressure from `28.8` to `13.4`. Full Python discovery passed `274/274` in `171.441s`; full Lua passed `853/853` in `16.23s`; compiler tests passed `16/16`; doctor and Kahlua checks passed with all required worker checks true and `0` Kahlua ERROR+ findings.

### Post-V5 Python package layout — runtime slice

**Status:** slice 1 implemented on existing `main`; commit `3045ac94`.

The Semantic Harness runtime boundary now lives under
`tools/semantic_harness/runtime/`: configuration discovery, scenarios, the
bounded JSON-lines protocol, Lua process lifecycle, the worker adapter, and
serialized worker sessions. The former top-level runtime modules are explicit
compatibility facades, so existing tests and callers retain their imports while
the implementation has one canonical package location. The Lua worker asset
remains at `tools/semantic_harness/lua/worker.lua`; no generated paths or
compiler behavior changed. The ignored `runtime/` directory rule was removed
from the harness `.gitignore` so the Python package is tracked.

Evidence:

- Focused runtime, protocol, worker-session, app, and runner checks: `21/21`
  passed before the final full-suite run.
- Full Semantic Harness Python discovery after the move: `276/276` passed in
  `169.613s`, exit `0`.
- Full embedded Lua regression:
  `python3 tests/run_tests.py --jobs 1 --harness-report /tmp/semantic-harness-runtime-slice-lua.json`
  — `853/853` passed in `15.99s`, exit `0`.
- Real worker doctor:
  `bash tools/semantic_harness/run_harness.sh --doctor --doctor-json` — all
  required checks true, including worker syntax and `READY/PING/CAPABILITIES`.

### Post-V5 Python package layout — studio slice

**Status:** slice 2 implemented on existing `main`; commit `c4e57bdf`.

The Semantic Lab authoring surface now lives under
`tools/semantic_harness/studio/`: canonical authoring/report operations,
workflow composition, dataset and block registry panes, typed interaction
composition, and the searchable production interaction catalog. The existing
`SemanticLabAuthoringService` and CodeBuilder service facade remain the single
authoring API. Former top-level modules are compatibility facades, so legacy
imports and direct test callers remain valid. No compiler, worker protocol,
generated asset path, or Lua runtime behavior changed.

Evidence:

- Affected authoring, interaction-spec, Flow Editor, dataset, app, and runtime
  checks: `49/49` passed.
- Full Semantic Harness Python discovery after the move: `276/276` passed in
  `168.964s`, exit `0`.
- Production imports now point to `studio/`; old top-level authoring modules
  are compatibility-only facades.

The inspection and presentation migration is recorded below.

### Post-V5 Python package layout — inspection slice

**Status:** slice 3 implemented on existing `main`; commit `1a914543`.

Bounded Conversation Inspector projections, JSON/CLI rendering, and transcript
storage now live under `tools/semantic_harness/inspection/`. The projection
still consumes the real worker observation and remains presentation-only; no
second semantic policy, response generator, or gameplay dispatcher was added.
Former top-level modules remain compatibility facades.

Evidence:

- Conversation Inspector, transcript, app, harness, and runtime checks:
  `43/43` passed.
- Existing worker response and inspection contracts remain unchanged.

The UI migration is recorded below.

### Post-V5 Python package layout — UI slice

**Status:** slice 4 implemented on existing `main`; commit `cdf84b1f`.

The Tk application shell now lives under `tools/semantic_harness/ui/`, with
the Flow Editor's pane, graph model, actions, canvas, and history grouped under
`ui/flow_editor/`. Runtime settings are under `ui/dialogs/`. The shell remains
a composition layer; graph state, compiler behavior, worker protocol, and
authoring service ownership did not change. Former top-level GUI and Flow
Editor modules remain compatibility facades.

Evidence:

- Flow Editor, worker session, app, inspector, and runtime checks: `28/28`
  passed.
- Full Semantic Harness Python discovery after the move: `276/276` passed in
  `170.048s`, exit `0`.
- Worker doctor after the move: all required checks true, including Lua syntax
  and `READY/PING/CAPABILITIES`.

The testing migration is recorded below.

### Post-V5 Python package layout — testing slice

**Status:** slice 5 implemented on existing `main`; commit `60e1a0bc`.

Case replay, conflict-ledger diagnostics, Lua smoke-suite execution, worker
doctor checks, and Phase 6 performance evidence now live under
`tools/semantic_harness/testing/`. The old top-level testing modules remain
compatibility facades. The legacy runner facade is a module alias so existing
module-level bound-limit patches continue to affect the canonical ledger.

Evidence:

- Runner, suite, app, harness, and performance checks: `45/45` passed.
- Full Semantic Harness Python discovery after the move: `276/276` passed in
  `170.970s`, exit `0`.
- `bash tools/semantic_harness/run_harness.sh --doctor --doctor-json` — all
  required checks true, including worker syntax and `READY/PING/CAPABILITIES`.

The package-entrypoint migration is recorded below. The remaining compatibility
facades are intentionally retained until downstream callers have a proven
removal gate; they are not duplicate implementations.

### Post-V5 Python package layout — package entrypoint slice

**Status:** slice 6 implemented on existing `main`; commit `618ed599`.

The harness now has local package metadata in the repository-root
`pyproject.toml`, a stable `python3 -m tools.semantic_harness` entrypoint, and
the existing CLI exposed as the `semantic-lab` project script. Package data
declarations include the existing worker/scenario assets and compiler JSON
sources without changing their paths.

Evidence:

- Package metadata parsed successfully with Python `tomllib`.
- `python3 -m tools.semantic_harness --help` exited `0` and loaded CLI help
  without starting Tk.
- Package-entrypoint focused checks passed `12/12`.

### Post-V5 Python package layout — dependency-boundary correction

**Status:** corrective slice implemented on existing `main`; commit `94368ed0`.

The architecture audit caught and the refactor removed a temporary
`codebuilder -> studio -> codebuilder` cycle. Canonical artifact authoring and
the pure interaction-catalog projection now live in `codebuilder/`. The former
root and Studio authoring/explorer paths are compatibility facades, while UI
and workflow modules depend downward on CodeBuilder. This preserves existing
imports without leaving a compiler-owned module dependent on the GUI package.

Evidence:

- Affected compatibility, authoring, interaction-spec, dataset, inspector, and
  package-entrypoint checks passed `42/42`.
- Final architecture scan: `169` source files (`103` production), `27,323` LOC,
  health `87.5`, coverage `67.0`, confidence `54.3`; no
  `DEPENDENCY_CYCLE` findings. Remaining findings are bounded-loop,
  large-function/module, known exception-handling, and one app coupling item.
- Final token scan: `179` files, `53` over the `2,000`-token review threshold
  when the ignored architecture-audit cache is excluded. The largest
  candidates are `codebuilder/interaction_spec.py`, Flow Editor/UI files,
  `studio/workflow.py`, and `codebuilder/authoring.py`; no behavior change was
  bundled into this folder migration to address those separate refactor seams.
- Full Semantic Lab Python discovery: `279/279` passed in `170.528s`, exit `0`.
- Full embedded Lua regression:
  `python3 tests/run_tests.py --jobs 1 --harness-report /tmp/semantic-harness-final-lua-boundary.json`
  — `853/853` passed in `16.09s`, exit `0`.
- Worker doctor:
  `bash tools/semantic_harness/run_harness.sh --doctor --doctor-json` — all
  required checks true, including worker syntax and `READY/PING/CAPABILITIES`,
  exit `0`.

No remaining developer-owned package-layout slice is required. Native Project
Zomboid SP/MP gameplay validation, live-server operation, installation, and
Workshop publishing remain user-owned as documented above.

## V1 — reusable visual CodeBlocks graph

**Status:** implemented and developer-verified. Commit: `c1913c9c`.

The existing Studio workflow now supports typed graph add/remove/configure/connect/disconnect operations for both backstory and registered capability interactions. It retains legacy `semantic.codeblocks.v1` action-flow compatibility, validates ports/cycles/orphans, keeps preview effect-free, requires explicit generation approval, and attaches deterministic graph metadata to the existing compiler output.

Evidence:

- Focused Python suite: 33 tests passed.
- Real Core+Hoomans Lua worker proof: the same visual service generated distinct backstory and registered `FOLLOW` assets; the worker returned `I worked as farmer before all this.` and `Okay, I will follow you for V1.`.
- GUI construction under Xvfb: exit 0; graph edit smoke: exit 0, 4 blocks and 3 connections.
- Generated EN/TL assets were deterministic and written only to the established mod asset directories.

## V2 — Core-backed localization

**Status:** existing implementation verified; final authored EN/TL acceptance evidence remains part of V5.

The existing `PsychopatzCustomTranslationManager`, `PNC.Translation`, registered catalogs/manifests, and legacy TextLoader compatibility remain the only localization path. Existing worker tests cover complete EN/TL sentences, dynamic `farmer` → `magsasaka` substitution, fallback diagnostics, language switching, and player-scoped privacy.

## V3 — personality-aware Knowledge disclosure

**Status:** implemented and developer-verified. Commit: `8adfe968`.

The existing Knowledge owner now evaluates topic alignment and private/personal disclosure willingness using the registered NPC personality/social style plus existing familiarity and approval. Familiarity remains eligibility only; guarded styles do not reveal facts without the stronger relationship context. Discovery, backstory preview/disclosure, and the semantic backstory fact provider pass the same topic context. No duplicate Knowledge service or per-NPC ModData was introduced.

Evidence:

- Real worker H3 suite: 5 tests passed. At familiarity 40, friendly disclosure produces the canonical English sentence and player dossier; withdrawn disclosure produces the refusal and no dossier.
- Lua smoke: `pnc_backstory_knowledge_disclosure_smoke`, 1/1 passed for friendly, guarded, and topic-mismatch cases.
- PZ Kahlua verification: 0 errors across the changed Knowledge directory and backstory fact-source file.

## V4 — persistence and Conversation Inspector

**Status:** implemented and developer-verified in the existing worker/inspector path. Commit: `920bda32`.

The existing `KNOWLEDGE_METRICS` worker command now serializes the complete canonical NPC record, backstory metadata, player-scoped Knowledge registry, and combined actor/Knowledge payload with the production Core deep-copy behavior. It preserves the legacy Knowledge byte field and reports the persisted ModData snapshot separately. The existing Conversation Inspector now projects a bounded readable acceptance chain: utterance, selected CodeBlock/graph fingerprint and edges, Core meaning, fact provider, Knowledge permission, translation lookups, actual NPC response, gameplay effects, and dossier delta. Generated semantic patterns now retain the existing graph metadata through the production catalog and worker observation.

Evidence:

- H4 worker suite: 3 tests passed, including legitimate 0/1/10 discovery comparisons and synthetic 100/1,000 NPC populations.
- Measured canonical worker records: 0 discoveries `actor=1002`, `backstory=0`, `knowledge=0`, `combined=1010` bytes; 1 discovery `actor=1608`, `backstory=593`, `knowledge=751`, `combined=2386`; 10 discoveries `actor=1623`, `backstory=593`, `knowledge=4887`, `combined=6537`; synthetic 1000/1 `knowledge=467754`, `combined=468783`, `npcCount=1000`.
- Conversation Inspector and V1 worker graph-provenance tests passed; graph metadata remains bounded and raw JSON remains an advanced diagnostic rather than the primary chain.
- Production-copy behavior was aligned with the native Core deep-copy implementation so the worker's diagnostic response bound cannot truncate persistence measurements.

## V5 — end-to-end Semantic Lab acceptance

**Status:** developer acceptance complete; ready for user-owned live Project Zomboid test after the final V5 evidence commit.

The existing Studio, CodeBuilder writer, real Core+Hoomans Lua worker, Knowledge/Dossier path, translation catalogs, and registered capability route now have an end-to-end acceptance proof. Preview remained effect-free, generation required explicit approval, generated Lua/EN/TL/manifest assets were written in an isolated mod tree, a fresh worker loaded them, and a response-block edit regenerated a different fingerprint and changed the final NPC response after restart. The same acceptance also covers a registered non-backstory interaction with existing capability side effects and no replacement authority.

Fresh developer evidence from this checkout:

- Acceptance code/test SHA: `c4bed07c1a7b8dac7b791069799731f8242afdae`; paired PsychopatzCore dependency SHA: `2179ee19307a993e186e6da661ad4212e984e0b4`.
- Focused V1–V5 Python command: 50 tests passed, exit 0. Full Semantic Lab Python discovery: 274 tests passed in 168.354s, exit 0. Full embedded compiler suite: 16 tests passed, exit 0.
- Full Lua regression: `python3 tests/run_tests.py --jobs 1 --harness-report /tmp/projecthoomans-v5-lua-harness.json` — 853/853 passed in 16.00s, exit 0.
- Doctor: `bash tools/semantic_harness/run_harness.sh --doctor --doctor-json` — all required checks true, including Tk/display, sibling Core, Lua 5.3, worker syntax, READY/PING/CAPABILITIES, exit 0.
- Kahlua: `pz_verify --mod-dir Contents/mods/ProjectHoomans/42.20 --kahlua --severity ERROR --no-snippets` — 2,947 files, 0 errors, exit 0.
- Actual Semantic Lab Tk pane under Xvfb: backstory graph composed through the GUI methods with 4 typed blocks and 3 connections; validation returned `ok=true`, preview returned `effectFree=true`, exit 0. No native Project Zomboid process or CUA surface was available, so no native gameplay/screenshot claim is made.
- Actual worker final text included `I worked as farmer before all this.`, `Okay, I will follow you for V1.`, and after the response-block regeneration `I will follow you after this graph edit.`. Tagalog fact-value acceptance returned `Nagtrabaho ako bilang magsasaka bago ang lahat ng ito.` with no fallback. Generated outputs were written to `Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Semantics/PNC_SemanticGroundedPersonalDialogue.lua`, `Contents/mods/ProjectHoomans/common/media/translation/EN/Conversation/Semantic/GroundedPersonalDialogue.json`, and `Contents/mods/ProjectHoomans/common/media/translation/TL/Conversation/Semantic/GroundedPersonalDialogue.json`; the established translation manifest remains `Contents/mods/ProjectHoomans/common/media/translation/manifests/Conversation.json`.

## Remaining mandatory chunk

No remaining developer-owned implementation chunk. Native Project Zomboid SP/MP gameplay validation remains user-owned.

`GOAL_PROMPT.md` was not created or modified.
