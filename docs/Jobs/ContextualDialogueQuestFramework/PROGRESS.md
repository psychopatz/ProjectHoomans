# Contextual Dialogue & Quest Framework — Current Progress

**Updated:** 2026-10-20

**Parent status:** **IN PROGRESS — H0–H4 required; not ready for user live test.**

**Current chunk:** H1 — registered Core-backed full-sentence backstory translation.

## Repository and dependency evidence

- Work is on the existing local `main` only. No new branch or worktree was created.
- The prior B0–B6 history was merged locally in `a3c5b5a7` (`Merge grounded personal dialogue implementation into main`) after read-only divergence and `git merge-tree` review. The eight canonical current-main documents were retained; the forbidden checked-in `GOAL_PROMPT.md` was excluded.
- Matching PsychopatzCore `main`: `2179ee19307a993e186e6da661ad4212e984e0b4`.
- Matching DynamicTrading `main`: `950b4f887e6f3cb3e311c659b852cbf3ec6f3883`.
- The local Hoomans `main` has not been pushed; remote integration must not be claimed until confirmed.

## H0 baseline and worker envelope

- Untouched `origin/main` with paired Core: Python `105 tests, OK`, exit 0; broad Lua exit 1 with exactly `pnc_semantic_local_route_smoke.lua` and `pnc_server_inventory_presence_boundary_smoke.lua` failing. An archived checkout without sibling Core produced setup-only `105 tests / 112 errors` and is not a product baseline.
- The merged B0–B6 tree reproduced the reported Python failure: `python3 -m unittest discover -s tools/semantic_harness/tests -q` returned `251 tests in 153.627s`, exit 1, `FAILED (errors=30)`. All 30 errors shared `Lua worker response exceeds the message limit` while fetching the generated flow catalog.
- Direct Lua measurements were handshake `22,646` bytes and `FLOW_CATALOG` `269,763` bytes against the previous `262,144`-byte bound. The bounded protocol repair is `e7a6adb8ffd2a77a7936016d22db95825b637aa`, raising the shared default to `512 KiB` and adding catalog-sized decode/rejection tests.
- Post-repair focused tests: `17/17`, exit 0. Doctor: `bash tools/semantic_harness/run_harness.sh --doctor --doctor-json`, exit 0. Full Python: `253 tests`, exit 0. The GUI command was launched with a bounded `timeout 8s`; it remained open as expected and returned 124. Tk/display checks were positive. No native Project Zomboid process was launched.
- The merged broad Lua suite remains `839/853`, exit 1, with the 14 known modules recorded in the preceding history; these are not being reported as fixed by the worker-envelope change.

## H0 real Semantic Lab trace

The trace used the existing Tk/Build Workflow/Conversation Inspector seams and fresh `LuaSemanticWorker` processes, with ordinary `INPUT` turns rather than the privileged `BACKSTORY_FACT` command.

| Input | Selected production candidate | Final worker observation | Side effect |
|---|---|---|---|
| `nice dress` | `pnc.social.compliment_adjective_feature`, COMPLIMENT, 1.0 | EN `Oh. Thank you, that's kind of you.`; Core-backed key `UI_PNC_Conversation_Semantic_ComplimentWithdrawn`, fallback false. TL resolved `Ay. Salamat, mabait mong sabihin iyan.` | none |
| `you got nice dress` | `pnc.social.compliment_you_got_feature`, COMPLIMENT, 1.0; inventory candidate `pnc.question.inventory_you_got` also present at 0.88 but not selected | same compliment response and no inventory request | none |
| `you got any bandages?` | `pnc.question.inventory_you_got`, QUESTION, 0.96 | inventory branch; no personal-dialogue response | `SemanticInventoryQuery` and `SemanticInventoryQueryResult`; `query_inventory` |
| `where are you from?` | `pnc.question.backstory.hometown`, QUESTION, 0.99; fact provider `npc_backstory`, status unknown, reason `backstory_not_disclosed` | client defers the local line pending authority; no final NPC message or translation lookup | `KnowledgeDisclosureRequest(topicID=backstory.hometown)` |
| `what are you afraid of?` | `pnc.question.backstory.fear`, QUESTION, 0.97; same fail-closed provider state | same deferred result; no final NPC message | `KnowledgeDisclosureRequest(topicID=backstory.fear)` |
| `what was your old job?` | no candidate | `I'm not sure what you mean.` | none |
| `where?` / `do you miss it?` | no candidate in the fresh default context | `I'm not sure what you mean.` | none |

The EN/TL trace therefore proves B0 candidate selection and existing Core-backed social localization, but also proves the H0 gaps: old-job and follow-up authoring coverage is absent; the normal worker has no disclosure completion/result hook or player-scoped dossier fixture; and refusal/known backstory sentences cannot be accepted through a deferred request alone. Familiarity eligibility is not being treated as disclosure. The existing Context Projection reads only the filtered `PNC.Network.ClientState.npcKnowledge` projection, not the local NPC record.

## CodeBuilder gap confirmed by source and compile contracts

- `tools/semantic_harness/codebuilder/compiler.py` currently limits exact dialogue question subjects to `ACTIVITY`, `IDENTITY`, `WELLBEING`, and `WEATHER`; `NPC_BACKSTORY` is not an authorable subject.
- The existing Flow Editor and `semantic.codeblocks.v1` expose registered facts, response pools, and context blocks, but no typed backstory provider/disclosure/evidence block or backstory-specific translation argument binding.
- The production response resolver already has stable backstory kinds and `content` arguments for authorized known/suspected facts, but the presentation map had no backstory response keys. That is the bounded H1 implementation target.

## Accepted chunks

- `6b783d09` — progress ledger for integration, exact baseline reproduction, protocol repair, doctor, and full post-fix Python evidence.
- `e7a6adb8ffd2a77a7936016d22db95825b637aa` — shared 512 KiB worker protocol/config bound and regression coverage.
- `a3c5b5a7` — local existing-main integration of prior B0–B6 history and current canonical H0–H4 documentation.

## Next mandatory chunk

Complete H1 by committing the registered EN/TL Backstory catalog and presentation argument binding, then verify the full authorized sentence through the real worker once the disclosure hook is available. Immediately continue H2: extend the existing CodeBuilder/compiler/Flow Editor contracts for typed `NPC_BACKSTORY` subjects, registered fact providers, disclosure states, response pools, follow-up references, and deterministic generation into actual mod Lua/catalog/manifest assets.
