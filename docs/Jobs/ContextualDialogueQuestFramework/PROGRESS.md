# C7 Conversational Competence — Progress

Status: READY FOR USER LIVE TEST. C7A–C7G are implemented and validated on the real PsychopatzCore + Project Hoomans Lua worker with PBrainZ disabled, with optional-provider parity covered. Native Project Zomboid live testing remains user-owned.

Repository baseline: `574b0898c92a6a19fb611897b4ff8647633cc651`.

Implementation branch: `codex/contextual-dialogue-quest-framework-0a`.

PsychopatzCore was inspected at `/home/psychopatz/Zomboid/Workshop/psychopatzCore`, HEAD `50022acf90d5a39995be552b7a1e1de21b59168b`; it was clean and was not modified.

## Required Semantic Lab reproduction

The required five-turn conversation was reproduced on the real worker before C7A implementation:

| Input | Core IR / pattern | Selected plan / final NPC text | Facts / side effects / trace |
| --- | --- | --- | --- |
| `do you have any news` | `GOSSIP/GOSSIP`; `pnc.social.news_do_you_have` | Existing `semantic.gossip`; “I haven't heard any news lately.” | No fact or side effect; recognized social interaction. |
| `wait here` | `REQUEST/REQUEST`, action `STAY`; `pnc.command.wait` | Existing command acknowledgement; “Okay, I'll stay.” | Existing STAY accepted; one CompanionCommand transport; authorized gameplay action. |
| `where do you live exactly` | No match | `ASK_CLARIFICATION`; “I'm not sure what you mean.” | No fact or side effect; unrecognized language. |
| `have you been bitten` | No match | `ASK_CLARIFICATION`; “I'm not sure what you mean.” | No fact or side effect; unrecognized language. |
| `i like your dress` | No match | `ASK_CLARIFICATION`; “I'm not sure what you mean.” | No fact or side effect; unrecognized language. |

## C7A accepted

Commit: `72a9c54c feat(semantic): implement C7A conversational competence`.

- Added reusable apparel/appearance `COMPLIMENT_FEATURE` categories for dresses, jackets, outfits, and appearance; reused the existing COMPLIMENT response system with personality and relationship context.
- Added self-directed medical/bite questions backed by `PNC.NPCWounds.BuildSnapshot`. Known wounds are reported, known bites are reported, and missing health data remains explicitly unconfirmed.
- Added trace distinctions for unrecognized language, recognized unknown questions, recognized social interaction, authorized gameplay action, and grounded NPC response.
- Added EN/TL and effect-free preview coverage. Preserved STAY, FOLLOW, NEWS, INSULT, THREAT, Gift, Quest, and inventory behavior.

## C7B accepted

Commit: `608494f7 feat(semantic): generalize grounded factual questions`.

- Generalized residence, NPC health, and NPC knowledge questions through authoritative local fact providers.
- Unknown facts remain explicit unknown responses; no location, medical history, knowledge, or gameplay action is invented.
- Added actual-worker EN/TL coverage for known residence, injured health, and known knowledge answers.

## C7C accepted

Commit: `8e36a4df feat(semantic): add C7C conversational continuity`.

- Added bounded “tell me more”, “what else”, “go on”, and equivalent continuation forms using existing conversation context.
- Added context-aware acknowledgements such as `what about your health` while preserving flow-owned ACCEPT behavior.
- Continuations use the preceding NPC answer subject and authoritative fact status; unknown health remains explicitly unconfirmed.
- Preview acknowledgement/continuation turns produce no gameplay transport, tool call, or LLM call.

## C7D accepted

Commit: `f362ab02 feat(semantic): add C7D discourse continuity`.

- Added bounded exact reference questions: `what about it/that/this`, `is it safe there`, `what is it like there`, and `does it still hurt`.
- Reused the existing participant-scoped `PNC.SemanticDialogueReferenceResolver`; no second parser or action route was introduced.
- Residence, health, and knowledge references re-query authoritative providers and remain truthful when facts are unknown.
- Needs flow remains intact: a proposal can be suspended by a weather question and resumed by `okay` without dispatching gameplay during preview.
- Gameplay-action responses do not create competing conversational topic candidates, preserving `WAIT_AT`/`STAY` target resolution. Separate worker sessions do not share topics or residence facts.

## C7E accepted

Commit: `31eb2c81 feat(studio): add conversation-first semantic inspection`.

- Extended the existing read-only Conversation Inspector with bounded `understanding`, `context`, `facts`, `dialoguePlanning`, and `finalResponse` sections sourced from the real worker record.
- Kept gameplay dispatch separate in `commandAuthority`, including action, binding, capability, authority, status, and effect counts. Raw worker data remains available in a separate view.
- Updated the Semantic Studio Simulation pane to show conversation understanding first, command authority separately, and raw worker data separately.
- Added real-worker inspector coverage proving grounded residence pronoun resolution while STAY remains an isolated authorized gameplay action.

## C7F accepted

Implementation commit: `d647af50 feat(semantic): measure reviewed language competence`.

- Extended the existing embedded CodeBuilder with a bounded, typed dialogue `match` form. Only the allowlisted Core concept `WEATHER` may be used, and literal match rules remain single-token and size-limited.
- Added three reviewed canonical patterns informed by existing MASSIVE/SGD mappings: `what is the weather like`, `is it still snowing`, and `what item do you mean`. Existing WordNet-reviewed FETCH aliases were measured alongside them.
- Regenerated the production Lua pattern artifacts through the existing CodeBuilder writer. No runtime corpus, external parser, second dialogue engine, or runtime LLM was added; raw external corpora remain outside runtime media.
- Added a bounded 14-case evaluation-only holdout with metadata-only WordNet 3.0/MASSIVE/SGD references. The real Lua worker scored 9 true positives, 0 false positives, and 0 false negatives: precision `1.0`, recall `1.0`, and 0 false executable dispatches across 14 protected cases.
- Real-worker response probes confirmed `what is the weather like` and `is it still snowing` select grounded weather plans with final NPC text “The weather looks clear right now.”; `what item do you mean` selects the clarification plan with “Understood.” Negative subject/scope/negation/follow-statement cases remain unrecognized and effect-free. EN/TL worker paths and generated key parity were checked.

## C7G accepted

Implementation commit: `f3b571e3 test(semantic): add C7G conversational acceptance gate`.

- Added a 14-turn EN/TL real-worker dialogue gate covering grounded residence, pronoun reference, continuation, medical status, needs/quantity/proposal context, weather interruption/resumption, NPC knowledge, compliments, gossip, effect-free preview, and one authorized STAY action.
- Verified personality variation changes response tone, template, and final text while preserving the same authoritative health fact reference and zero gameplay effects.
- Verified two participant scopes retain separate residence facts and participant IDs; one NPC/player's conversation cannot resolve another scope's residence.
- Compared the same long grounded conversation with the optional provider enabled and disabled. IR, response plan, context, final messages, transport, and tool calls remained identical; recognized turns made no provider or gameplay authority call.
- Measured the sustained real-worker dialogue within the existing latency and bounded-context budgets: p95 turn latency at or below 1 second, mean at or below 250 ms, recent turns at or below 12, mentions at or below 32, and focus at or below 8.

## Validation evidence

All semantic behavior below used the real Lua worker unless explicitly marked compiler/static validation:

- C7A + C7B + C7C + C7D focused harness tests: `18/18`.
- C7E conversation-inspector plus C7A–C7D focused tests: `22/22`.
- C7F focused held-out/compiler tests: `2/2`.
- C7G integrated acceptance gate: `5/5`.
- Full semantic harness suite after C7G: `244/244`.
- Production semantic Lua smoke tests: `68/68`.
- Semantic compiler tests: `16/16`.
- Reviewed lexicon smoke: `1/1`.
- Doctor: PASS for Python, Tk/display, Lua, worker syntax, Core repository, and READY/PING/CAPABILITIES handshake.
- `pz_verify --kahlua --severity ERROR --no-snippets`: 3,049 files scanned, 0 Kahlua errors, 0 i18n errors, 0 bloat findings.
- Changed Lua passed `luac5.3 -p`; 65 translation JSON files parsed; EN/TL generated dialogue and semantic key sets remain aligned.
- `git diff --check` passed. No native Project Zomboid launch, multiplayer host, mod installation, Workshop publish, second NLP parser, second dialogue engine, runtime LLM, or invented NPC fact was introduced.

## Next Chunk

USER LIVE TEST — run the mandatory five-turn conversation in native Project Zomboid SP/MP with the intended mod/Core loadout, then optionally validate a real PBrainZ bridge and report any native-only authority, translation, persistence, or multiplayer divergence.
