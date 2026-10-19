> **CURRENT B-phase expansion (2026-10-20):** See `GROUNDED_PERSONAL_DIALOGUE_B.md` and live `PROGRESS.md` B0. Prior C7 acceptance is archived as historical 244/244 harness, 68/68 semantic Lua, 16/16 compiler; it was not a test of the newer `nice dress` / `you got nice dress` collision nor of player-specific learned NPC biography. New B0–B6 gates are mandatory for the expanded product. Do not mistake old C7 "ready" as approval to require user-owned native Project Zomboid testing now.

> **2026-10-19 Active C7 clarification:** The C0–C6 text below is historical design/acceptance scope, partly implemented and recorded passed in previous ledgers. The NEW required conversation-quality gates are in `CONVERSATIONAL_COMPETENCE_C7.md` and active `PROGRESS.md`. C7A first: real worker reproduces user screenshot and improves clothing compliments and directed bite questions across paraphrases with truthful facts/unknown and actual final NPC text. Following phases require NPC follow-up initiative, context across turns and a conversation-first graph. Do not treat previous 218/218 harness results as C7 acceptance.

# Contextual conversation developer acceptance — real Lua worker

**These gates are NEW, planned, and have NOT been executed by this docs update.** Real production PsychopatzCore and Hoomans Lua worker loaded from a known checkout is required. Python-only IR simulation, dataset statistics, generated JSON, mock screenshot or fabricated NPC transcript do not qualify. Mocked world/authority boundaries must be identified.

## C0 baseline and targeted regressions

Before new implementation, record current real-worker outputs/IDs for:
- wellbeing followed by "What happened?" with known/unknown injury cause;
- "Do you need anything?" → "How many?" with supplied/absent item quantity;
- "I'll get them" after one and two candidate items, demonstrating safe item resolve vs clarify;
- change topic to weather then "Anyway, about your leg…" with appropriate topic resumption;
- "Why?" after refusal, with reason available vs unavailable;
- INSULT "fuck you" → hostile reaction rather than generic "I couldn't do that right now." unless *actual* authority is denied, in which case text must still be a truthful social-response failure. Test end-user visible reply not merely IR;
- current four recorded `ContextualSocialReactionTests` THREAT variants (trusted/withdrawn/stressed/precedence), investigate and preserve honest failures or repair them with source-backed cause;
- no second NPC/player memory leakage and no unauthorized action from "yes", "do it", "it", "some";
- existing generated companion command, task, gift and quest action smoke with no duplicate dispatch.

Use observed failures to pick ONE C0 repair/extension chunk after G3C, not blindly rewrite parser or add duplicate regexes.

## C1 conversation frames / referents

Same real-worker turn series must show normalized IR/candidate, selected contextual interpretation, current/past focus, agenda entry (open/fulfilled/expired), confidence/ambiguity, active/suspended flow and final NPC text. "How many?" works across 2 distinct domains via ONE reusable resolution contract, not 2 handcrafted patterns. Ambiguity clarifies and zero effects. Preview does not change state.

## C2 durable memory / promises

NPC A recognizes accepted promise tied to actual owner event after conversation close+reopen or worker save/load fixture; NPC B does not inherit it. Unconfirmed player claim and missing NPC observation are not fact. Expiry/unknown produce honest responses. Compact storage bound, revision/source ID and explicit owner.

## C3 planner + realization

Plan actually selects communicative act, fact source, dialogue response pool and tone based on personality/relationship + known world/quest state. Changing personality changes *presentation/willingness* without altering facts. Test unknown/denied/pending/complete authority results and truthful phrasing. EN/TL keys present. Optional PBrainZ can't authorize game changes.

## C4 dataset Code Builder

Deterministic sample manifest/license/provenance; reviewable candidates, rejections, negatives and collisions; compiled Lua translation/manifest in correct mod paths; fresh worker recognizes reviewed sample and rejects negatives with no false dispatch; exact diff and repeat byte-identical output. No raw copied corpus lines unless cleared. Document unsupported EN/TL patterns.

## C5 Semantic Lab UI

Actual existing Tk/X11 mouse or keyboard test (when available), no requirement for Codex desktop CUA: select scenario, step through turns, inspect context agenda/topic/focus/evidence, show memory owner and reason for clarification, see actual response plan and effects, edit/review a supported corpus mapping, preview compilation and worker restart. Direct Tk callbacks alone are NOT mouse click-through acceptance; when display cannot be controlled, mark UI PENDING only and continue code.

## C6 scale, isolation, compatibility

No per-tick full-population text/NPC scan, no redundant full-chat ModData, bounded per-turn allocations/retrieval time and memory per NPC, actual measured scenario latency and corpus-size budget. EN/TL, multi-NPC/player, server-only quest results, negative actions, server/client authority, reconnect and worker restart tests. Native PZ SP/MP remains **user-owned** and cannot be marked passed by a headless worker.

## Acceptance trace minimum

`source SHA + Core revision | scenario/language | speaker/addressee/conversation | utterance | selected IR + confidence | interpreted dialogue act / unresolved alternatives | topic/focus/agenda before/after | verified fact references/provenance | authorized flow/action outcome | chosen response plan/pool | final translated NPC text | transport+sideEffects+LLM calls | preview/commit`.

A test passes only if both semantic interpretation **and visible reply/real effect** are correct.
