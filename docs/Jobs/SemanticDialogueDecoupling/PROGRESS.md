# Semantic Dialogue Decoupling — current corrective state

**Updated:** 2026-10-17
**Phase:** C0 — compatibility and deployment audit
**State:** C0A audit complete; C0B handshake implementation is complete in the checkout, but installed Workshop parity and native acceptance remain pending. The product is **not maintenance-ready**.

This is the one active progress ledger for this goal. C1–C6 were not started in this chunk.

## C0A result

The source-level semantic path is compatible in the current local pair, but installed Workshop parity and a native capability handshake are still unproven. The broken external pz-headless-harness was not used. The repository’s internal tools/semantic_harness was used only for isolated production-module verification; it is not native PZ proof.

## Revision and deployment matrix

| Surface | Identity | Result |
| --- | --- | --- |
| Hoomans checkout | main 1de5f9208d5624931dca88a46a22f4efe40ad239; origin/main remains 56288e50e6d782634df7f26ceaa0f0cb7c0922f9; uncommitted C0B handshake files present | Complete 42.20 mod, manifest, EN/TL shards, semantic sources, and the new read-only capability spoke; local docs commit is one commit ahead |
| PsychopatzCore checkout | main 44a4d534a9520440070ae7943d7ae9fb848f71ce; origin/main is identical | Semantic/parser/router/manifest additions are published on GitHub; preserve unrelated dirty edits in .architecture-refactor/output/architecture-audit.md and tools/asset_harness/** |
| Local Workshop pair | /home/psychopatz/Zomboid/Workshop/ProjectHoomans plus /home/psychopatz/Zomboid/Workshop/psychopatzCore | Only complete current pair found locally |
| Steam Hoomans cache | Workshop 3799685526 | Incomplete fragment: only 42.20/media/lua/shared/PNC/Core/Compatibility/Mods/Bandits/PNC_Bandits_AnimPathCompat.lua; no mod.info, current semantic files, or translation manifest |
| Steam Core cache | Workshop 3799682704 | Directory absent; no complete Steam Core package was found |
| Native session | Prior /home/psychopatz/Zomboid/console.txt; no current PZ process | The prior run loaded mod IDs PsychopatzCore, MarketSense, DTCommon, ProjectHoomans, and DTHoomans and produced the expected English SP spot-check; it predates the handshake and does not expose exact filesystem origin |

The GitHub Core publication does not need a source-level correction for C0A: 56906aa exposes Parser.ParseCandidates, 9e46a8e adds router candidate/flow hooks, and afc1bda adds manifest catalogs. Steam Workshop publication/install parity remains unresolved and must be handled as C0B, with separate publication authorization.

## Key file fingerprints at audit time

| Checkout-relative path | SHA-256 |
| --- | --- |
| Hoomans/Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/Semantics/PNC_SemanticDialogueInput.lua | 4fe03b079fc1f2a3abb2988f536c42261a7cdad83acb4230d91cd07bc0b8dbda |
| Hoomans/Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Translation/PNC_TranslationBootstrap.lua | 04355c037b67f6dbb46349d976eec948868b5a9af5251002658f7b8a836cc49d |
| Hoomans/Contents/mods/ProjectHoomans/common/media/translation/manifests/Conversation.json | 054c3826ace4d826bbec4a539c3fe6f9b17657a43a0886843d8ca4a48c53fa85 |
| Hoomans/Contents/mods/ProjectHoomans/common/media/translation/EN/Conversation/Semantic/Responses.json | 997dc14ec9b5bafe95f12e5e9e12101ca6d1d7b095fbb96582c077ff37bf4859 |
| Hoomans/Contents/mods/ProjectHoomans/common/media/translation/TL/Conversation/Semantic/Responses.json | ee613dc802a3ca5f4721e5bc70403f26d3b5287898679bb696352903e537640f |
| Core/Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Semantics/PsychopatzSemanticParser.lua | a639c5bbf68ca8da296180ebd08783011da2b40ceeba7f781900576f97125ba0 |
| Core/Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Semantics/PsychopatzSemanticDialogueRouter.lua | 1a123b1fb3948f7599ec11159e61476fffe78f8a28dd057b988660a7a06350ee |
| Core/Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Translation/PsychopatzCustomTranslationManifest.lua | bfad4350d90b0801e0a8b4116ef8c69d3f714c2c9d26f72ffab48d7bb4967ee8 |

## API and source verification

- Hoomans PNC_SemanticDialogueInput_Context.lua:118 calls PsychopatzCore.Semantics.Parser.ParseCandidates and returns candidate_parser_unavailable instead of silently substituting a parser.
- Hoomans PNC_SemanticDialogueInput_RouterLifecycle.lua:70-104 passes the candidate parser and Policy.SelectCandidate into DialogueRouter.New, and installs them through the Core setters when available.
- Core PsychopatzSemanticParser.lua:320-439 exports the bounded candidate bundle with selected candidate and diagnostics.
- Core PsychopatzSemanticDialogueRouter.lua:67-80,151-214,216-275 accepts candidate parser/selector hooks and calls policy.CommitFlow during ProcessIR.
- Hoomans PNC_TranslationBootstrap.lua:17-40 registers Conversation with Scope.registerSystem("Conversation", "media/translation", "manifests/Conversation.json"); the other systems retain the two-argument registration form.
- Core PsychopatzCustomTranslationManager.lua:242-383,789-846 reads packaged files through getModFileReader, validates the manifest, merges only declared shards, and accepts the optional manifest path. Core media is intentionally excluded from the graph, so these Core claims were verified by direct source fallback after coverage reported the exclusion.
- Hoomans 42.20/mod.info still declares only require=PsychopatzCore,MarketSense; there is no feature-specific minimum or explicit runtime capability handshake. No Hoomans capability marker was found in the captured native log. C0B must make this mismatch fail-visible.
- C0B checkout change: `PNC_SemanticCapabilityHandshake.lua` is an optional, read-only diagnostic spoke. The semantic input lifecycle reports `semantic.capability_handshake` when audit is enabled, and the turn-trace adapter retries the report if the setting is enabled later. The record includes the Hoomans source marker/fingerprints, observed Core API marker, `ParseCandidates`, candidate selection, router candidate hooks, `CommitFlow`, manifest registration/read state, language, shard count, and an explicit bounded failure list.
- The handshake deliberately does not reimplement Core or alter parser/dialogue/gameplay/network state. A missing optional spoke emits an explicit `capability_handshake_module_unavailable` record; a loaded but incompatible Core/manifest emits named missing capabilities.

## Translation and native evidence

- Contents/mods/ProjectHoomans/common/media/translation/manifests/Conversation.json declares 12 EN and 12 TL Conversation shards. The EN/TL semantic response shards are distinct; their current hashes are 997dc14e... and ee613dc8... respectively.
- lua5.3 tests/pnc_translation_catalog_smoke.lua, lua5.3 tests/pnc_conversation_translation_fallback_smoke.lua, and lua5.3 tests/pnc_semantic_dialogue_flow_smoke.lua pass.
- Direct Lua regression checks after the C0B change pass: `pnc_semantic_diagnostics_smoke.lua` (matched and mismatch handshake paths), `pnc_semantic_dialogue_input_smoke.lua`, `pnc_semantic_identity_presentation_smoke.lua`, `pnc_semantic_identity_transport_smoke.lua`, and `pnc_semantic_dialogue_response_plan_smoke.lua`. `luac5.3 -p` and focused `pz_verify --kahlua --severity ERROR` checks are clean for each changed runtime Lua file.
- The internal harness test test_response_plan_crosses_real_en_and_tl_presentation passes, as do the live-entrypoint parity tests. This proves the checked-out worker uses production Lua modules, not that native PZ loaded the same files.
- The captured native SP session produced semantic audit records for identity, wellbeing question, clarification, hunger, and fine-state inputs. The user-visible conversation screenshot also showed the expected deterministic responses. The native run exercised English only; there is no native EN/TL lookup/fallback provenance, no native MP run, and no exact installed-file hash handshake.
- The bounded console scan found no Hoomans semantic exception or candidate_parser_unavailable; it did contain unrelated vanilla/map warnings and errors, which are not being attributed to this goal.

## Focused verification

- python3 -m unittest tools.semantic_harness.tests.test_semantic_live_parity -v: 4/4 PASS.
- python3 -m unittest tools.semantic_harness.tests.test_semantic_identity_wellbeing_collision -v: 9/9 PASS.
- python3 -m unittest tools.semantic_harness.tests.test_semantic_dialogue_flows -v: 5/5 PASS.
- Core parser and manifest smokes: PASS.
- lua5.3 tests/psychopatz_custom_core_translation_smoke.lua: FAIL at the stale assertion expecting 316 entries. A read-only run reports the current coverage snapshot as total=362, translated=336, with zero missing keys/catalogs. This is a Core test-maintenance item, not evidence that the Hoomans manifest API is unavailable.
- No external headless harness was run, and no headless result is being used as native acceptance.

## C0A exit and C0B status

C0A exit is satisfied: the local, GitHub, Steam-cache, and native-runtime matrix is recorded with exact current revisions and an actionable deployment path. The read-only C0B handshake is now implemented and directly smoke-tested in the checkout. C0B is not accepted as a deployment gate until the following remaining work is performed:

1. With separate authorization, build/republish complete Workshop packages for Core 3799682704 and Hoomans 3799685526 from matching clean revisions; do not overwrite the two unrelated dirty Core files.
2. After deployment, restart PZ and capture a native `semantic.capability_handshake` record showing the installed source marker/fingerprints, Core API marker, `ok=true`, and the manifest reader/catalog load state. A mismatch must remain explicit and actionable.
3. Correct or derive the stale Core translation-count assertion in the Core-owned test after the Core change is authorized; do not alter it during this C0A audit.
4. Capture native EN/TL loaded-vs-fallback provenance, then run the same bounded SP dialogue matrix and a separate MP check.

Do not begin C1–C6 until C0B establishes installed-pair identity and native capability/translation evidence.
