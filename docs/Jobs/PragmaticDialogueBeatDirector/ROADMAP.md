# Roadmap — Pragmatic Dialogue Beat Director

**Parent status:** READY TO IMPLEMENT.
**Developer completion boundary:** P8.

A phase or chunk completing is not completion of this parent goal. When running
under the autonomous `/goal`, accept each phase, update `PROGRESS.md`, then
continue automatically through the next mandatory phase.

## P0 — baseline, parity, and contracts

### P0A — reproduce the current conversation seam

Using the real production Lua worker:

- reproduce the recognized-hostile → displayed-response path represented by the
  user-observed Semantic Lab case and protected hostile-language tests;
- record Core candidates/IR, selected policy branch, flow state, response pool,
  ResponsePlan, translation, rendered text, and side effects;
- repair any verified production/harness parity defect causing recognized
  hostile meaning to fall into generic clarification;
- preserve ambiguous-input clarification behavior.

### P0B — freeze director/compiler contracts

- map existing FlowRegistry/FlowKernel/ContextState/ResponsePlan and CodeBuilder
  seams;
- define bounded beat/behavior schemas and observation envelope;
- define canonical compiler ownership for beat/behavior metadata and strings;
- prove no duplicate parser/compiler/decision authority is needed.

**Gate:** baseline behavior is truthful and the new contracts map to existing
owners rather than parallel systems.

## P1 — compiler-backed Beat/Behavior registries

Implement production data-only registries and compiler support.

Required:

- validated beat definitions;
- reusable behavior definitions;
- stable canonical IDs;
- manifest-backed canonical source shards;
- generated bounded Lua artifacts;
- generated audit/provenance metadata;
- compiler-generated first-party beat/behavior strings and translation keys;
- locale bundles discovered data-first with EN fallback;
- deterministic second generation;
- collision/duplicate/reachability/reference validation.

No beat-specific production wording may be hardcoded in Lua/Python.

**Gate:** edit one canonical beat/content source record, regenerate, and prove
the expected Lua + locale artifact changes deterministically while unrelated
artifacts remain stable.

## P2 — Pragmatic Resolver and Dialogue Director

Implement production runtime arbitration.

Required:

- pragmatic interpretation consumes real NLU/context, not a second parser;
- bounded topic/obligation/reference/social-event context;
- beat entry/maintain/exit;
- active-beat stickiness/cooldowns;
- behavior eligibility and contextual modifiers;
- deterministic/explainable winner;
- explicit no-behavior path;
- existing ResponsePlan output/augmentation;
- no direct unauthorized gameplay mutations.

**Gate:** the same utterance can select meaningfully different behaviors under
different grounded NPC/relationship contexts while semantic meaning remains
constant.

## P3 — worker observation and headless inspection

Extend the real worker observation/CLI with:

- pragmatic interpretation;
- beat candidates;
- failed predicates;
- activeBefore/activeAfter;
- entered/exited beats;
- behavior candidates and applied modifiers;
- selected behavior;
- ResponsePlan/content lineage;
- explicit harness override markers.

No Python re-interpretation.

**Gate:** an agent can explain one turn end-to-end from text → semantic meaning
→ context → beat → behavior → plan → rendered text/side effects using bounded
worker evidence.

## P4 — Semantic Lab Beat Studio

Add Beat Studio inside the existing Semantic Lab/Studio.

Required:

- browse/search canonical production beats/behaviors;
- visual entry/maintain/exit predicate editing;
- candidate behavior editing;
- cooldown/limit/group editing;
- raw normalized advanced view;
- Validate Draft;
- Preview Draft against current scenario/turn;
- worker-local Register Draft;
- Open/Save bounded draft;
- visible Draft / Worker Registered / Canonical status;
- no direct packaged-source mutation from worker registration.

Reuse existing Flow Editor/session/service patterns.

**Gate:** create or modify a draft beat, validate and preview it, worker-register
it, then exercise it through a real multi-turn production Lua conversation
without restarting native PZ.

## P5 — Simulation beat inspector, timeline, and compiler promotion

### Inspector

Show human-readable:

- why each beat was eligible/ineligible;
- why a beat entered/exited/remained;
- behavior candidate ranking and modifiers;
- selected behavior;
- resulting ResponsePlan and content source.

### Timeline

Provide a bounded turn timeline showing at least player/NPC turns, active flow,
active beat, and beat transitions.

### Promotion

Beat Studio promotion must use the shared CodeBuilder authoring API:

- canonical-ID edit;
- validation;
- generated diff preview;
- explicit write/compile;
- worker restart/reload;
- post-generation replay.

All semantic/domain strings come from canonical compiler inputs.

**Gate:** an accepted draft can be promoted without hand-editing generated Lua
or translation JSON, and the reloaded worker behavior matches the promoted
canonical definition.

## P6 — initial emergent beat set

Implement enough real content to prove generality, initially:

- suspicious first contact;
- argument escalation;
- reconciliation.

Use reusable behaviors rather than beat-specific bespoke code.

Required demonstrations include:

- hostile remark can escalate an argument;
- aggression/confidence/relationship context can favor warning or retaliation;
- fear/danger context can favor de-escalation or exit;
- apology can enable reconciliation;
- unrelated active flows can suspend/resume where appropriate;
- no beat invents facts or bypasses gameplay authority;
- response wording varies through compiler-owned Dialogue Content.

**Gate:** multi-turn behavior emerges from definitions/context, not a handwritten
conversation tree.

## P7 — authoring/test workbench

Add:

- Natural / Force eligible / Force active / Disable diagnostic modes;
- visible `HARNESS_OVERRIDE` markings;
- scenario matrix runner over personality/relationship/world variants;
- Save as Regression Case from a successful conversation;
- expectations based on semantic/beat/behavior/allowed response pools and
  forbidden side effects rather than exact wording where variation is intended;
- headless replay using the same real worker.

**Gate:** focused override testing and natural arbitration are clearly
distinguished, and captured cases replay deterministically enough to catch
semantic/director regressions.

## P8 — integrated developer acceptance

Acceptance must prove:

- real Core + Project Hoomans Lua worker path;
- hostile-recognition parity regression fixed/preserved;
- flows and beats coexist without duplicated ownership;
- three initial beats run naturally across multi-turn cases;
- personality/relationship/danger variation changes behavior appropriately;
- beat/behavior strings and response wording are compiler-owned;
- EN fallback and TL/current additional locale behavior remain valid;
- adding a synthetic locale requires no locale whitelist code;
- CodeBuilder two-pass idempotence;
- source/generated ownership and provenance are inspectable;
- no direct generated-file authoring;
- no unintended authoritative side effects;
- optional PBrainZ consumes the same plan/authority when exercised;
- bounded memory/trace/catalog behavior;
- relevant Python, native Lua, Kahlua/static verification, diff checks, and
  source/save safety pass.

Only after P8 developer gates pass may the job become **READY FOR USER LIVE
TEST**. Native PZ SP/MP remains user-owned unless explicitly reassigned.

## Non-goals

- do not reproduce Façade scripts or content;
- do not create a general LLM as the offline director;
- do not make beats a replacement for flows;
- do not encode final prose inside beat definitions;
- do not move relationship/inventory/task/world mutation into the director;
- do not resume unrelated P11 wording migrations merely because this job uses
  the same compiler foundation.
