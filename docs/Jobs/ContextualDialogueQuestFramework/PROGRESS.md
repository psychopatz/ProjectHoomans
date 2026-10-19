# C7 Conversational Competence — Progress

Status: C7 in progress. C7A and the bounded C7B chunk are implemented and validated on the real PsychopatzCore + Project Hoomans Lua worker with PBrainZ disabled. Native Project Zomboid live testing remains user-owned.

Repository baseline: `574b0898c92a6b19fb611897b4ff8647633cc651`.

Current implementation branch: `codex/contextual-dialogue-quest-framework-0a`, two commits ahead of `origin/docs/contextual-dialogue-quest-framework-20261018` (`72a9c54c` C7A and `f89c4f80` C7B). PsychopatzCore dependency was inspected at `/home/psychopatz/Zomboid/Workshop/psychopatzCore`, HEAD `50022acf90d5a39995be552b7a1e1de21b59168b`; it was clean and not modified.

## Required Semantic Lab reproduction

The original five-turn conversation was reproduced on the real worker before the C7A implementation:

| Input | Core IR / pattern | Selected plan / final NPC text | Facts / side effects / trace |
| --- | --- | --- | --- |
| `do you have any news` | `GOSSIP/GOSSIP`, `GOSSIP`; `pnc.social.news_do_you_have` | `GOSSIP_RECEIVED`, existing `semantic.gossip`; “I haven't heard any news lately.” | No fact or side effect; `recognized_social_interaction`. |
| `wait here` | `REQUEST/REQUEST`, action `STAY`; `pnc.command.wait` | Existing command acknowledgement; “Okay, I'll stay.” | Existing stay command was accepted; one `CompanionCommand` transport; `authorized_gameplay_action`. |
| `where do you live exactly` | No match | `ASK_CLARIFICATION`; “I'm not sure what you mean.” | No fact or side effect; `unrecognized_language`. |
| `have you been bitten` | No match | `ASK_CLARIFICATION`; “I'm not sure what you mean.” | No fact or side effect; `unrecognized_language`. |
| `i like your dress` | No match | `ASK_CLARIFICATION`; “I'm not sure what you mean.” | No fact or side effect; `unrecognized_language`. |

After C7A and C7B, the same worker sequence is now:

| Input | Core IR / pattern | Selected plan / final NPC text | Facts / side effects / trace |
| --- | --- | --- | --- |
| `do you have any news` | `GOSSIP/GOSSIP`, `GOSSIP`; `pnc.social.news_do_you_have` | `GOSSIP_RECEIVED`, `semantic.gossip`; “I haven't heard any news lately.” | No side effect; social interaction → grounded response. |
| `wait here` | `REQUEST/REQUEST`, `STAY`; `pnc.command.wait` | `COMMAND_ACCEPTED`; “Okay, I'll stay.” | Existing `PNC.Client.SendCompanionCommand`, capability `pnc:companion.stay`, one transport; authorized gameplay action. |
| `where do you live exactly` | `QUESTION/QUESTION`, `NPC_RESIDENCE`; `pnc.question.residence.where_do_you_live` | `FACT_ANSWER`, `semantic.question.residence.unknown`; “I don't have a confirmed home to tell you about.” | `client_npc_context_projection`, `npc_residence_unavailable`; no side effect; recognized question with unknown fact. |
| `have you been bitten` | `QUESTION/QUESTION`, `NPC_BITE_STATUS`; `pnc.question.medical_bite.have_you_been` | `MEDICAL_STATUS`, `semantic.question.medical_bite.unknown`; “I can't confirm whether I've been bitten.” | `client_npc_health_projection`, `npc_health_projection_unavailable`; no side effect; recognized question with unknown fact. |
| `i like your dress` | `COMPLIMENT/COMPLIMENT`, `RECIPIENT`; `pnc.social.compliment_i_like_your_feature` | Existing relationship/personality-aware `semantic.compliment`; “Oh. Thank you, that's kind of you.” | No side effect; social interaction → grounded response. |

## C7A accepted

Commit: `72a9c54c feat(semantic): implement C7A conversational competence`.

- Added reusable apparel/appearance compliment categories through the existing `COMPLIMENT_FEATURE` catalog and relationship-aware social response path. Positive examples include dress, jacket, outfit, and appearance; negative “I don't like your dress” remains unrecognized.
- Added typed self-directed bite questions and the authoritative `PNC.NPCWounds.BuildSnapshot` projection. Complete wound data yields known positive/negative answers; missing or partial data yields the truthful unknown response and never fabricates a negative bite status.
- Added simulation trace classifications for unrecognized language, recognized unknown questions, recognized social interactions, authorized gameplay actions, and grounded NPC responses.
- Added EN/TL response keys and preview-effect-free coverage.

## C7B implementation

- Added reusable residence, health-state, and open-ended knowledge question patterns. Knowledge topics remain bounded captures; unresolved topics are allowed through the read-only local-fact policy so the NPC can answer that it lacks reliable information rather than asking an unrelated clarification.
- Added `client_npc_context_projection` for explicit NPC residence, derived dialogue health state, explicit topic knowledge, and relationship context. Missing facts remain `unknown` with a provider reason.
- Added a production detailed-snapshot residence projection sourced only from `PNC.Communities.Get(record.affiliation.communityID)`; no location is inferred from current position or faction alone.
- Added typed `FACT_ANSWER` plans, grounded fact references, provenance, EN/TL translations, captured-topic formatting, and dynamic authoritative knowledge text.
- Extended the real Lua worker scenario projection for residence and topic knowledge, while retaining the existing inventory summary and command paths.
- Preserved the existing inventory-query async/read-only path, relationship response path, and authorized STAY command. A semantic smoke regression caught and removed an overlapping `home` concept alias that shadowed the existing `GO HOME` command.

## Validation evidence

All checks below used the real Lua worker unless explicitly marked as compiler/static validation:

- C7A + C7B focused harness tests: `9/9`.
- Full semantic harness suite: `227/227`.
- Semantic compiler tests: `16/16`.
- Production semantic Lua smoke tests: `68/68`.
- Harness doctor: Python 3.12.3, Tk/display, Core repository, Lua 5.3.6, worker syntax and boot all passed.
- `luac5.3 -p` passed for every changed Lua file.
- `pz_verify --kahlua --severity ERROR --no-snippets` passed across the mod: 3049 files scanned, 0 flagged, 0 errors.
- EN/TL response JSON parsed successfully with exact key parity: 117/117 in each language. C7B residence, health-state, and knowledge keys are present in both languages.
- Preview tests showed no messages, transport, tool calls, or LLM calls and byte-equivalent semantic state before/after preview.
- Known-fact worker probes produced grounded residence `Riverside Camp`, injured health, and the authoritative knowledge answer “It is north of here.” Unknown probes produced truthful responses with no gameplay effects.
- Existing acceptance probes retained news, STAY, FOLLOW, INSULT, THREAT, Gift, Quest, inventory, and command-authority behavior; the semantic smoke suite specifically caught and verified the `GO HOME` preservation issue.
- `git diff --check` passed. The broad i18n scanner still reports its pre-existing repository-wide hardcoded-string inventory; no new gameplay/UI translation path was introduced, and all new conversational response keys have EN/TL parity.

## Scope boundary

This chunk does not claim native Project Zomboid live readiness. It does not launch the game, host multiplayer, enable PBrainZ, install mods, or publish to Workshop. Production residence data is only exposed when the authoritative community projection is present; otherwise the NPC remains uncertain.

## Next Chunk

C7C — NPC conversational initiative, relevant follow-ups, acknowledgements, and natural topic continuation.
