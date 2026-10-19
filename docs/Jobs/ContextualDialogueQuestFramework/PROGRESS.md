# C7 Conversational Competence — Progress

Status: C7 is in progress. C7A, C7B, C7C, and C7D are implemented and validated on the real PsychopatzCore + Project Hoomans Lua worker with PBrainZ disabled. Native Project Zomboid live testing remains user-owned.

Repository baseline: `574b0898c92a6b19fb611897b4ff8647633cc651`.

Implementation branch: `codex/contextual-dialogue-quest-framework-0a`.

Accepted implementation commits: `72a9c54c` (C7A), `608494f7` (C7B), `8e36a4df` (C7C), and `f362ab02` (C7D).

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

- Added reusable apparel/appearance compliment categories through the existing `COMPLIMENT_FEATURE` relationship/personality-aware social response path. Dress, jacket, outfit, and appearance paraphrases are covered; negative dress statements remain unrecognized.
- Added typed self-directed bite questions using authoritative `PNC.NPCWounds.BuildSnapshot` data. Complete wound data can produce positive/negative status; missing or partial data stays unknown and never fabricates medical history.
- Added residence, health-state, and open-ended knowledge questions as read-only local-fact queries with EN/TL responses and effect-free preview.
- Added trace distinctions for unrecognized language, recognized unknown questions, recognized social interaction, authorized gameplay action, and grounded NPC response.
- Preserved inventory, relationship, STAY, FOLLOW, INSULT, THREAT, Gift, Quest, and inventory behavior.

## C7B accepted

Commit: `608494f7 feat(semantic): generalize grounded factual questions`.

- Generalized residence, NPC health, and NPC knowledge question patterns and reused the authoritative local fact providers.
- Unknown facts remain explicit unknown responses; no location, medical history, or knowledge is invented.
- Added actual-worker EN/TL and preview coverage, including known residence, injured health, and known knowledge answers.

## C7C accepted

Commit: `8e36a4df feat(semantic): add C7C conversational continuity`.

- Added bounded “tell me more”, “what else”, “go on”, and equivalent continuation forms using existing conversation context.
- Added context-aware acknowledgements and `what about your health`, while preserving flow-owned ACCEPT behavior.
- Continuations use the preceding NPC answer subject and authoritative fact status; unknown health remains explicitly unconfirmed.
- Preview and acknowledgement/continuation turns produce no gameplay transport, tool call, or LLM call.

## C7D accepted

C7D implements conversation continuity, pronoun resolution, commitment preservation across topic switches, and participant-scoped context using existing dialogue state, reference resolution, flow state, and fact providers.

- Added bounded exact reference-question patterns for `what about it/that/this`, `is it safe there`, `what is it like there`, and `does it still hurt`. These produce normal QUESTION IR with captured references; they are not a second parser or an action route.
- Reused the existing `PNC.SemanticDialogueReferenceResolver` and participant-scoped context mentions. NPC response topics are compact discourse focus only; authoritative providers answer the bound subject.
- Residence and knowledge references re-query known facts and return grounded final NPC text. Safety, description, and medical follow-ups remain truthful unknown responses when no authoritative provider can confirm them.
- Unknown medical sequences (`are you hurt` → `does it still hurt` → `what about that`) never produce a fabricated healthy/injured/negative answer.
- Existing needs commitments remain flow-owned: `do you need anything` → `how many` → `i will get some` opens a proposal confirmation; a weather question suspends it; `okay` resumes the pending proposal without dispatching a gameplay action.
- Gameplay-action responses do not create competing conversational topic candidates. This preserves `WAIT_AT`/`STAY` target resolution, including `wait at campfire` → `wait there`.
- Separate worker sessions do not share residence or topic mentions. Preview does not mutate context, queue messages, or transport gameplay effects.
- Added EN/TL response keys for unknown context references, location safety, place description, and medical pain.

## Validation evidence

All semantic behavior below used the real Lua worker unless explicitly marked compiler/static validation:

- C7A + C7B + C7C + C7D focused harness tests: `18/18`.
- Full semantic harness suite: `236/236`.
- Production semantic Lua smoke tests: `68/68`.
- Semantic compiler tests: `16/16`.
- Generated lexicon smoke: `1/1`.
- Harness doctor: PASS — Python 3.12.3, Tk/display, Core repository, Lua 5.3.6, worker syntax, worker boot, PING, and CAPABILITIES.
- `luac5.3 -p` passed every changed Lua file.
- `pz_verify --kahlua --severity ERROR --no-snippets`: 3049 files scanned, 0 flagged, 0 errors.
- EN/TL response JSON parsed successfully with exact key parity: `132/132`.
- `git diff --check` passed and the new C7D Python test compiled.
- No native Project Zomboid launch, multiplayer host, mod installation, Workshop publish, second NLP parser, second dialogue engine, runtime LLM, or invented NPC fact was introduced.

## Next Chunk

C7E — Conversation-first Semantic Studio visualization showing actual understanding, context, facts, dialogue planning, and final response. Keep command-authority graphs separately.
