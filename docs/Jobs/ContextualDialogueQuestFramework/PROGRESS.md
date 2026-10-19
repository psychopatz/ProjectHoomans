# Contextual Dialogue & Quest Framework — Current Progress

**Updated:** 2026-10-19 after the real-worker C7A implementation and validation.

**Status:** C7 Conversational Competence remains in progress and is not yet ready for the user’s expanded live-test gate.

**Source baseline:** `574b0898c92a6b19fb611897b4ff8647633cc651` on `codex/contextual-dialogue-quest-framework-0a`, tracking `origin/docs/contextual-dialogue-quest-framework-20261018`.

**PsychopatzCore used by the worker:** `/home/psychopatz/Zomboid/Workshop/psychopatzCore` at `50022acf90d5a39995be552b7a1e1de21b59168b`. Core was left unchanged.

## Historical foundation preserved

R0A–R5B remains the accepted foundation archived in `HISTORY_R0_R5B_20261019.md`. This change does not replace the existing parser, dialogue engine, response planner, action dispatcher, CodeBuilder, world-knowledge projection, quest authority, or optional PBrainZ boundary.

## C7A — accepted

### Required five-turn reproduction

The starting worker reproduction used the real `tools/semantic_harness/run_harness.sh` Lua worker with PBrainZ disabled. Before the implementation, the exact five inputs produced the already-observed behavior: news was recognized as GOSSIP, `wait here` dispatched STAY, and residence, bite status, and the dress compliment were no-match clarification turns.

After the implementation, the same worker and exact sequence produced this evidence:

| Input | Core IR / pattern | Decision and selected plan | Facts and final NPC text | Side effects / Simulation trace |
|---|---|---|---|---|
| `do you have any news` | `GOSSIP/GOSSIP`, subject `GOSSIP`; `pnc.social.news_do_you_have` | deterministic `GOSSIP_RECEIVED`; `semantic.gossip`, `GOSSIP_RECEIVED` | no fact required; `I haven't heard any news lately.` | no action or transport; `recognized_social_interaction` → `grounded_npc_response` |
| `wait here` | `REQUEST/REQUEST`, action `STAY`; `pnc.command.wait` | deterministic `COMMAND_ACCEPTED`; existing command response plan | no fact; `Okay, I'll stay.` | one accepted existing `PNC.Client.SendCompanionCommand`, capability `pnc:companion.stay`, one `CompanionCommand` transport; `authorized_gameplay_action` |
| `where do you live exactly` | no intent/pattern; `diagnostics.noMatch=true` | deterministic `ASK_CLARIFICATION` | no fact; `I'm not sure what you mean.` | no action, transport, or tool call; `unrecognized_language` |
| `have you been bitten` | `QUESTION/QUESTION`, subject `NPC_BITE_STATUS`, target `SELF`; `pnc.question.medical_bite.have_you_been` | deterministic `QUESTION_RECEIVED`; `semantic.question.medical_bite.unknown`, `QUESTION_RECEIVED`, topic `MEDICAL`, uncertainty `unknown` | `client_npc_health_projection`, reason `npc_health_projection_unavailable`; `I can't confirm whether I've been bitten.` | no action, transport, or tool call; `recognized_question_unknown_fact` → `grounded_npc_response` |
| `i like your dress` | `COMPLIMENT/COMPLIMENT`, subject `RECIPIENT`; `pnc.social.compliment_i_like_your_feature` | deterministic `COMPLIMENT_RECEIVED`; existing `semantic.compliment`, relationship-aware withdrawn response | no fact required; `Oh. Thank you, that's kind of you.` | no action, transport, or tool call; `recognized_social_interaction` → `grounded_npc_response` |

The trace now records `classification`, fact status/provider/reason, response selection, response-plan metadata, and bounded side-effect status. It distinguishes language no-match, recognized questions whose facts are unknown, recognized social interactions, authorized gameplay actions, and the selected deterministic NPC response.

### Reusable implementation

- Added a bounded `BITE` concept and direct self-directed medical question families for “have you been bitten”, “are you bitten”, “did a zombie bite you”, “any bites”, and closely related forms. Existing third-person `BITTEN` gossip remains separate.
- Added `client_npc_health_projection`, a read-only fact provider for `NPC_BITE_STATUS`. It consumes the existing authoritative `bodyHealth` projection from `PNC.NPCWounds.BuildSnapshot`; a complete `wounds={}` projection is a known negative, while missing or partial health data is unknown. No injury, history, or negative bite status is fabricated.
- Added positive, negative, and truthful-unknown medical response pools with response plans and EN/TL keys.
- Expanded the existing `COMPLIMENT_FEATURE` category with apparel and appearance vocabulary, article-aware “you have a …” forms, and reusable `your/that feature is/looks adjective` forms. All apparel responses use the existing `COMPLIMENT` branch and relationship/personality response catalog; no exact sentence branch was added.
- Added trace-side response grounding metadata without adding a parser, dialogue engine, runtime LLM, compiler, or gameplay dispatcher.

### Authority and language checks

The real worker ran with `providerAvailable=false` and `llmCalls=0`. Known bite-positive and bite-negative tests used the production health projection boundary; the unknown cases stayed deterministic and transport-free. EN and TL rendered through the existing PsychopatzCore translation manager. The Semantic response catalogs have 110 EN keys and 110 TL keys with zero key-parity differences, including the three new medical keys per language.

Preview of the bite question was accepted by the production router but emitted no message, transport, tool call, or LLM call and left the initialized session snapshot unchanged. The existing STAY, NEWS, social, wellbeing, identity, and other accepted behavior remained in the regression suites. No native Project Zomboid process, multiplayer host, Workshop upload, or mod installation was used.

### Validation evidence

- C7A real Lua worker tests: **4/4**.
- Existing contextual and live-parity regression tests: **27/27**.
- Focused harness, translation, CodeBuilder, and social-reaction tests: **51/51**.
- Full Semantic Lab Python harness discovery: **222/222**, `104.743s`.
- Focused semantic compiler suite: **16/16**.
- Real Lua semantic smoke suite: **68/68** (`python3 tests/run_tests.py pnc_semantic`).
- Harness doctor: passed Python 3.12.3, Tk/display, repository, Core repository, Lua 5.3.6, worker syntax, and worker boot/PING/CAPABILITIES.
- `luac5.3 -p`: all changed Lua files passed. `pz_verify --kahlua`: all changed Lua files passed with zero errors. Changed response catalogs also passed the i18n check. EN/TL JSON parsing and key parity passed. `git diff --check` passed.

## Next Chunk

**C7B — Generalized factual questions about NPC residence, health, inventory, relationships, and knowledge.**
