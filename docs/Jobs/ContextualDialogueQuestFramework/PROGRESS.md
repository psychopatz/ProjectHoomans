# C7 Conversational Competence — Progress

Status: C7 in progress. C7A, C7B, and C7C are implemented and validated on the real PsychopatzCore + Project Hoomans Lua worker with PBrainZ disabled. Native Project Zomboid live testing remains user-owned.

Repository baseline: `574b0898c92a6b19fb611897b4ff8647633cc651`.

Implementation branch: `codex/contextual-dialogue-quest-framework-0a`. The accepted prior commits are `72a9c54c` (C7A) and `608494f7` (C7B). PsychopatzCore was inspected at `/home/psychopatz/Zomboid/Workshop/psychopatzCore`, HEAD `50022acf90d5a39995be552b7a1e1de21b59168b`; it was clean and not modified.

## Required Semantic Lab reproduction

The required five-turn conversation was reproduced on the real worker before C7A implementation:

| Input | Core IR / pattern | Selected plan / final NPC text | Facts / side effects / trace |
| --- | --- | --- | --- |
| `do you have any news` | `GOSSIP/GOSSIP`, `GOSSIP`; `pnc.social.news_do_you_have` | Existing `semantic.gossip`; “I haven't heard any news lately.” | No fact or side effect; `recognized_social_interaction`. |
| `wait here` | `REQUEST/REQUEST`, action `STAY`; `pnc.command.wait` | Existing command acknowledgement; “Okay, I'll stay.” | Existing STAY accepted; one CompanionCommand transport; `authorized_gameplay_action`. |
| `where do you live exactly` | No match | `ASK_CLARIFICATION`; “I'm not sure what you mean.” | No fact or side effect; `unrecognized_language`. |
| `have you been bitten` | No match | `ASK_CLARIFICATION`; “I'm not sure what you mean.” | No fact or side effect; `unrecognized_language`. |
| `i like your dress` | No match | `ASK_CLARIFICATION`; “I'm not sure what you mean.” | No fact or side effect; `unrecognized_language`. |

After C7A and C7B, the same sequence is now:

| Input | Core IR / pattern | Selected plan / final NPC text | Facts / side effects / trace |
| --- | --- | --- | --- |
| `do you have any news` | `GOSSIP/GOSSIP`; `pnc.social.news_do_you_have` | `semantic.gossip`; “I haven't heard any news lately.” | No side effect; social interaction → grounded response. |
| `wait here` | `REQUEST/REQUEST`, `STAY`; `pnc.command.wait` | `COMMAND_ACCEPTED`; “Okay, I'll stay.” | Existing `PNC.Client.SendCompanionCommand`, capability `pnc:companion.stay`, one transport; authorized gameplay action. |
| `where do you live exactly` | `QUESTION/QUESTION`, `NPC_RESIDENCE`; `pnc.question.residence.where_do_you_live` | Unknown `FACT_ANSWER`; “I don't have a confirmed home to tell you about.” | `client_npc_context_projection`, `npc_residence_unavailable`; no side effect; recognized question with unknown fact. |
| `have you been bitten` | `QUESTION/QUESTION`, `NPC_BITE_STATUS`; `pnc.question.medical_bite.have_you_been` | Unknown `MEDICAL_STATUS`; “I can't confirm whether I've been bitten.” | `client_npc_health_projection`, `npc_health_projection_unavailable`; no side effect; recognized question with unknown fact. |
| `i like your dress` | `COMPLIMENT/COMPLIMENT`; `pnc.social.compliment_i_like_your_feature` | Existing relationship/personality-aware `semantic.compliment`; “Oh. Thank you, that's kind of you.” | No side effect; social interaction → grounded response. |

## C7A accepted

Commit: `72a9c54c feat(semantic): implement C7A conversational competence`.

- Added reusable apparel/appearance compliment categories through the existing `COMPLIMENT_FEATURE` and relationship/personality-aware social response path. Dress, jacket, outfit, and appearance paraphrases are covered; a negative dress statement remains unrecognized.
- Added typed self-directed bite questions using authoritative `PNC.NPCWounds.BuildSnapshot` data. Complete wound data can produce positive/negative status; missing or partial data stays unknown and never fabricates medical history.
- Added residence, health-state, and open-ended knowledge questions as read-only local-fact queries with EN/TL responses and effect-free preview.
- Preserved inventory, relationship, STAY, FOLLOW, INSULT, THREAT, Gift, and Quest behavior. A smoke regression caught and removed an overlapping `home` alias that shadowed `GO HOME`.

## C7B accepted

Commit: `608494f7 feat(semantic): generalize grounded factual questions`.

- Residence uses only explicit NPC residence or the authoritative community projection; absent data remains `npc_residence_unavailable`.
- Health uses the existing NPC health projection; absent data remains `npc_health_projection_unavailable`.
- Knowledge uses bounded authoritative topic projections and preserves the captured topic in the final response. No location, rumor, relationship, or knowledge is inferred.
- The real worker exposes scenario residence, topic knowledge, and inventory summary through the existing worker snapshot seam; no second parser, dispatcher, or engine was added.

## C7C accepted

- Added reusable `MORE` vocabulary and bounded continuation patterns for “tell me more”, “can you say more”, “say more”, “what else”, “anything else”, “go on”, “keep going”, “continue”, and “can you tell me more”. Complete-utterance matching keeps phrases such as “give me more food” out of the continuation route.
- Continuation is resolved from the immediately preceding NPC answer and preserves the existing topic across repeated turns. Gossip with no authoritative statement answers that there is nothing more to add; residence, health, and knowledge continuations remain bounded and do not invent facts.
- Added context-aware acknowledgements for personal factual answers. “Okay” after a relationship or NPC-health answer retains the topic and returns the existing relationship acknowledgement or personality-aware conversational acknowledgement. Flow-owned ACCEPT turns still resume the existing needs/proposal flow.
- Added the natural health continuation “what about your health” through the existing health-question provider. Known and unknown medical continuation responses are distinct; unknown health remains explicitly unconfirmed.
- Extended the existing trace to distinguish a recognized continuation question from a question with an unknown engine fact and to record the selected response source. Preview remains effect-free, and continuation/acknowledgement turns produce no transport or tool calls.

## Validation evidence

All semantic behavior below used the real Lua worker unless explicitly marked compiler/static validation:

- C7A + C7B + C7C focused harness tests: `13/13`.
- Full semantic harness suite: `231/231`.
- Semantic compiler tests: `16/16`.
- Production semantic Lua smoke tests: `68/68`.
- Harness doctor: Python 3.12.3, Tk/display, Core repository, Lua 5.3.6, worker syntax, and worker boot all passed.
- `luac5.3 -p` passed every changed Lua file.
- `pz_verify --kahlua --severity ERROR --no-snippets`: 3049 files scanned, 0 flagged, 0 errors.
- EN/TL response JSON parsed successfully with exact key parity: `128/128` in each language.
- Real worker probes verified known residence, injured/healthy/unknown health, authoritative knowledge, repeated topic continuation, relationship acknowledgement, and TL continuation text.
- Preview comparisons showed no messages, transport, tool calls, LLM calls, or semantic state mutation before/after preview.
- Existing acceptance probes retained news, STAY, FOLLOW, INSULT, THREAT, Gift, Quest, inventory, needs/weather flow resumption, and command-authority behavior.
- `git diff --check` passed. The broad i18n scanner's repository-wide hardcoded-string inventory remains pre-existing; new C7C response keys have exact EN/TL parity.

Scope boundary: this chunk does not launch native Project Zomboid, host multiplayer, install mods, publish to Workshop, add an LLM dependency, or invent NPC facts. Native live testing remains user-owned.

## Next Chunk

C7D — Conversation continuity, pronoun resolution, commitments, topic switching, and participant-scoped memory.
