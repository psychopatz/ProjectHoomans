# Semantic Dialogue Refinement & Variation Expansion — current progress

**Parent goal status: COMPLETE.**

## Planning baseline

- ProjectHoomans HEAD at job creation: `b3836b2ce35fb1161e92cf0bdb041f81e5016ae9`.
- Existing Quality Sweep parent goal is recorded complete and is an accepted dependency.
- Worktree was clean at planning start.
- No production content was changed during P0 planning.

## Corpus baseline

Canonical conversation phrase audit:

- active style-family combinations: **729**
- below 10 phrases: **729**
- exactly 1 phrase: **660**
- exactly 2 phrases: **19**
- exactly 3 phrases: **29**
- exactly 5 phrases: **4**
- exactly 6 phrases: **17**
- already >=10: **0**

Current compiler bound:

`MAX_PHRASES_PER_STYLE = 16` (raised from 6 in P1A).

## Phase state

| Phase | State |
| --- | --- |
| P0 — audit / contract | **COMPLETE (planning)** |
| P1 — capacity + inventory tooling | **COMPLETE** |
| P2 — core conversation | **COMPLETE** |
| P3 — social | **COMPLETE** |
| P4 — commands/tasks | **COMPLETE** |
| P5 — events/combat | **COMPLETE** |
| P6 — remaining corpus / exemptions | **COMPLETE** |
| P7 — corpus-wide acceptance | **COMPLETE** |

## Accepted P1 Evidence

1. **Bounded phrase capacity raised (P1A)**:
   - Raised `MAX_PHRASES_PER_STYLE` from 6 to 16 in `tools/semantic_harness/codebuilder/dialogue_content.py`.
   - Compiler enforces 1..16 bounds and rejects >16 with compile errors.
   - Verified existing <=6 content regenerates with 100% byte-for-byte idempotent parity (`git diff` clean).
   - Added capacity unit tests in `test_dialogue_variation_auditor.py` covering boundary checks (16 accepted, 17 rejected, empty rejected).

2. **Machine-readable corpus variation auditor (P1B & P1C)**:
   - Implemented `tools/semantic_harness/codebuilder/variation_auditor.py` with `audit_corpus()`, normalization, placeholder parity, duplication checks, EN-identical TL checks, Quality Sweep evidence integration, and Markdown ledger generation.
   - Exposed CLI interface via `app.py`: `--variation-audit`, `--variation-audit-json`, `--variation-audit-ledger`, `--variation-audit-shard`, `--variation-audit-under-10`.
   - Audited all 505 canonical phrase families and all 729 canonical style buckets across all 21 manifest content shards (85 registered JSON shard files).
   - Generated initial classification ledger at `docs/Jobs/SemanticDialogueRefinementVariation/CLASSIFICATION_LEDGER.md`:
     - `EXPAND_TO_10`: 683 style buckets (NPC spoken dialogue across core, social, commands, tasks, events, combat, quest, knowledge, navigation).
     - `THIRD_PARTY_COMPAT_DEFERRED`: 27 style buckets (external third-party compatibility fallback phrases in `content/compatibility.json`).
     - `PLAYER_UI_OUT_OF_SCOPE`: 19 style buckets (player avatar command and emote callouts in `content/command/player.json` and `content/social/emotes/player.json`).
     - `ATOMIC_EXEMPT`: 0.
     - `STRUCTURAL_NOT_PHRASE`: 0.
     - Under-10 eligible buckets: **683 / 683**.
   - Added unit test suite `test_dialogue_variation_auditor.py` (7 tests, all passing in 0.04s).

2. **Phase 2 (Core Conversation Refinement & Expansion) — COMPLETED**:
   - **P2A (Greeting / Farewell)**:
     - `content/greeting.json`: Expanded all 7 families / 13 styles to 10 variants each (130 phrases).
     - Fixed inappropriate romantic terms ("sweetheart", "love") in guarded/terse/warm styles.
     - Preserved canonical initial greeting for test backward compatibility.
   - **P2B (Wellbeing / Health / Needs)**:
     - `content/wellbeing.json`: Expanded all 11 families / 20 styles to 10 variants each (200 phrases).
     - `content/health.json`: Expanded all 6 families / 24 styles to 10 variants each (240 phrases). Replaced robotic "recorded bite" lines with grounded survivor speech.
     - `content/needs.json`: Expanded all 10 families / 13 styles to 10 variants each (130 phrases). Replaced bureaucratic "record a commitment" phrasing.
   - **P2C (Conversation & Identity / Ask Name)**:
     - `content/conversation.json`: Expanded all 5 families / 20 styles to 10 variants each (200 phrases).
     - `content/social/tool_replies/ask_name.json`: Expanded all 8 families / 8 styles to 10 variants each (80 phrases). Fixed fake English TL copies and enforced strict `%s` placeholder parity.
   - **Compiler & Shard Capacity**:
     - Raised `CONVERSATION_CONTENT_MAX_SHARD_BYTES` in `dialogue_content.py` and `CONVERSATION_MAX_SHARD_BYTES` in `conversation_compiler.py` to 128KB to support bounded 16-phrase expansion.
     - Regenerated 196 Lua and JSON translation artifacts across EN and TL with complete parity.
     - Verified real Lua worker phrase reachability across pool size 10.
     - All 25 compiler, context health, content authority, and auditor unit tests pass.
   - **Corpus Metrics After P2**:
     - Styles at >=10 phrases: **98 / 729** (was 0).
     - Eligible under-10 style buckets: **585 / 683** (was 683).

3. **Phase 3 (Social Interaction Refinement & Expansion) — COMPLETED**:
   - **P3A (Social Tool Replies & Social Apology)**:
     - 14 tool reply shards (accepted_generic, admire, apology, comfort, compliment, flirt, hostile, insult, orientation, personality, praise, relationship, romantic, sexual): expanded all 32 styles to 10 variants each (320 phrases). Replaced fake English TL copies with natural Tagalog/Taglish.
     - `content/social_apology.json`: expanded all 4 families / 16 styles to 10 variants each (160 phrases), differentiating neutral/warm/terse/guarded voices and eliminating identical default lines.
   - **P3B (Social Emotes & Reactions)**:
     - `content/social/emotes/reply.json` (18 styles) & `conversation.json` (4 styles): expanded to 10 variants each (220 phrases). Removed forbidden "love" pet-name from warm salute; authored authentic TL lines.
     - `content/social/reactions.json`: expanded all 11 families / 52 styles to 10 variants each (520 phrases), preserving `%s` placeholder signatures in all 8 `bond_*` styles.
   - **P3C (Social Interaction & Director / Scene Runtime Adopters)**:
     - 11 interaction shards (argument_deescalate, argument_retaliate, context_clarify, first_contact_challenge, memory_acknowledge, memory_acknowledge_flavor, memory_followup, news_acknowledge, world_event_warning, world_event_warning_flavor, social_conversation_director): expanded all 49 styles to 10 variants each (490 phrases).
     - `content/social/interaction/scene_runtime_adopters.json`: expanded all 15 families / 48 styles to 10 variants each (480 phrases). Replaced cartoon profanity caricature lines with grounded survivor speech; preserved `{clock}` and `{relative}` placeholders across both EN and TL.
   - **Compiler & Shard Bounds**:
     - Raised `CONVERSATION_MAX_SOURCE_BYTES` to 128KB and `CONVERSATION_MAX_SHARD_BYTES` to 192KB to accommodate bounded 10-phrase expansion in 52-style shards like `reactions.json`.
     - Regenerated all 196 Lua modules and EN/TL translation artifacts.
     - All 25 compiler, context health, content authority, and auditor unit tests pass.
   - **Corpus Metrics After P3**:
     - Styles at >=10 phrases: **323 / 729** (was 98).
     - Eligible under-10 style buckets: **360 / 683** (was 585).
     - Remaining under-10 styles in social domain: **0**.

4. **Phase 4 (Commands & Tasks Refinement & Expansion) — COMPLETED**:
   - **P4A (Command Replies)**:
     - `content/command/replies.json`: expanded all 19 styles to 10 variants each (190 phrases). Replaced cartoon profanity with grounded survivor combat and command dialogue.
   - **P4B (Command Lifecycle)**:
     - `content/command/lifecycle/*.json` (`camp.json`, `follow.json`, `return_home.json`, `stay.json`, `stop_following.json`): expanded all 35 styles (5 files * 7 styles) to 10 variants each (350 phrases), covering `acknowledged`, `started`, `blocked`, `failed`, `interrupted`, `completed`, `progress`.
   - **P4C (Task Lifecycle)**:
     - `content/task/lifecycle/*.json` (`consume.json`, `drink.json`, `eat.json`, `fetch.json`, `gift.json`, `give.json`, `refill.json`, `wait_at.json`): expanded all 40 styles (8 files * 5 styles) to 10 variants each (400 phrases), covering `started`, `blocked`, `failed`, `interrupted`, `completed`.
   - **P4D (Task Tool Replies)**:
     - `content/task/tool_replies/*.json` (21 shards: `cooldown`, `order_camp`, `order_follow`, `order_generic`, `order_rejected`, `order_stay`, `queued_admire`, `queued_apology`, `queued_comfort`, `queued_compliment`, `queued_flirt`, `queued_generic`, `queued_hostile`, `queued_insult`, `queued_praise`, `queued_romantic`, `queued_sexual`, `rejected_game`, `rejected_generic`, `rejected_hostile`, `rejected_sexual`): expanded all 46 styles to 10 variants each (460 phrases). Replaced all English-identical TL strings with authentic Tagalog/Taglish translations.
   - **Verification**:
     - Regenerated all 196 Lua modules and EN/TL translation artifacts.
     - All 25 compiler, context health, content authority, and auditor unit tests pass.
   - **Corpus Metrics After P4**:
     - Styles at >=10 phrases: **463 / 729** (was 323).
     - Eligible under-10 style buckets: **220 / 683** (was 360).
     - Remaining under-10 styles in command and task domains: **0**.

5. **Phase 5 (Combat & Events Refinement & Expansion) — COMPLETED**:
   - **P5A (Player Assault Reactions)**:
     - `content/combat/player_assault_reactions.json`: expanded all 5 styles to 10 variants each (50 phrases), providing distinct survivor reactions across shaken, aggressive, brave, reserved, and default personalities.
   - **P5B (Weapon Kill Reactions)**:
     - `content/combat_banter/weapon_kill_reactions.json`: expanded all 26 styles to 10 variants each (260 phrases). Preserved `{combatWeaponDisplayName}` in all 10 EN and 10 TL realizations of `firearm_high_named_01`. Replaced cartoon profanity caricatures with visceral, grounded zombie takedown dialogue.
   - **P5C (Human Kill Reactions)**:
     - `content/combat_human_banter/human_kill_reactions.json`: expanded all 21 styles to 10 variants each (210 phrases), addressing the psychological gravity of taking human lives across aggressive, supportive, shaken, brave, reserved, cold, and practical personalities.
   - **P5D (Horde Reactions & Kill Events)**:
     - `content/event/combat_horde_reactions.json`: expanded all 11 styles to 10 variants each (110 phrases) across horde encounter phases (started, escalated, deescalated, prompts, and tactical choices).
     - `content/event/combat_kill_killer_reactions.json`: expanded all 21 styles to 10 variants each (210 phrases).
     - `content/event/combat_kill_witness_reactions.json`: expanded all 21 styles to 10 variants each (210 phrases).
     - `content/event/reactions.json`: expanded all 19 styles to 10 variants each (190 phrases). Eliminated 19 suspicious English-identical TL lines by authoring authentic Tagalog/Taglish localizations.
   - **P5E (Medical Distress & Treatment)**:
     - `content/event/medical.json`: expanded all 32 styles to 10 variants each (320 phrases). Replaced robotic clinical announcements with urgent, visceral distress calls (bandage, bleedout, dehydration, starvation, exhaustion, rescue, mercy) and authentic Tagalog localizations.
   - **Infrastructure**:
     - Raised `DEFAULT_MAX_MESSAGE_BYTES` in `tools/semantic_harness/runtime/protocol.py` and `tools/semantic_harness/lua/worker/Protocol.lua` from 512KB to 1024KB (1MB) to support the larger serialized flow and phrase catalog on worker startup.
     - Regenerated 196 Lua modules and translation artifacts; all 25 unit tests passed in 29.9s.
   - **Corpus Metrics After P5**:
     - Styles at >=10 phrases: **619 / 729** (was 463).
     - Eligible under-10 style buckets: **64 / 683** (was 220).
     - Remaining under-10 styles in combat and event domains: **0**.

6. **Phase 6 (Remaining Corpus: Quest, Knowledge, Navigation & Exemption Reconciliation) — COMPLETED**:
   - **P6A (Quest Dialogue)**:
     - `content/quest.json`: expanded all 4 families / 12 styles to 10 variants each (120 phrases), covering quest offers, acceptance, refusal, and completion.
   - **P6B (Knowledge & Gossip Dialogue)**:
     - `content/knowledge.json`: expanded all 7 families / 32 styles to 10 variants each (320 phrases), covering gossip, location, identity, and activities.
     - Preserved `%s` placeholder signatures across all 8 bond and known identity styles.
     - Preserved `%1` topic interpolation across all 4 styles in `semantic.question.knowledge.known`.
   - **P6C (Navigation Dialogue)**:
     - `content/navigation.json`: expanded all 6 families / 20 styles to 10 variants each (200 phrases), covering cardinal directions, wayfinding, landmarks, and spatial navigation.
   - **Formal Exemption Reconciliation**:
     - `THIRD_PARTY_COMPAT_DEFERRED`: 27 styles (`content/compatibility.json`) verified as external mod compatibility stubs.
     - `PLAYER_UI_OUT_OF_SCOPE`: 19 styles (`content/command/player.json`, `content/social/emotes/player.json`) verified as player avatar UI commands/emotes.
     - Zero unclassified or ambiguous records remain across the entire project.
   - **Corpus Metrics After P6**:
     - Styles at >=10 phrases: **683 / 729**.
     - Eligible under-10 style buckets: **0 / 683** (**100% COMPLETE!**).

7. **Phase 7 (Corpus-Wide Closeout & Full Verification) — COMPLETED**:
   - **Corpus-Wide Audit Report**:
     - Total canonical phrase families: **505**
     - Total canonical style buckets: **729**
     - `EXPAND_TO_10` style buckets: **683** (all 683 have exactly 10 variants).
     - `THIRD_PARTY_COMPAT_DEFERRED`: **27**
     - `PLAYER_UI_OUT_OF_SCOPE`: **19**
     - `eligible_under_10_count`: **0** (Mandatory final result achieved: `EXPAND_TO_10 buckets below 10 = 0`).
   - **CodeBuilder Determinism & Idempotence**:
     - Full conversation manifest compilation regenerates 196 files with byte-for-byte idempotence (`git diff` clean).
     - Clean `git diff --check` with zero trailing whitespace or formatting defects.
   - **Syntax & Language Verification**:
     - `luac -p` verified all generated Lua runtime modules.
     - `json.load` verified all 91 translation files and all source shards.
     - EN/TL placeholder signatures strictly matched across `{name}`, `%s`, `{clock}`, `{relative}`, `{combatWeaponDisplayName}`, and `%1`.
     - Zero suspicious English-identical TL strings in expanded dialogue content.
   - **Regression Suite Verification**:
     - All 4 P11B migration contracts (`test_p11b_health_migration.py`, `test_p11b_needs_migration.py`, `test_p11b_social_apology_migration.py`, `test_p11b_wellbeing_migration.py`) pass 100%.
     - `test_conversational_competence_c7a.py`, `c7b.py`, `c7c.py`, `c7d.py`, `c7g.py` pass 100%.
     - `test_automatic_flow_generation.py`, `test_gift_capability_binding.py`, `test_contextual_runtime_parity_p11a.py` pass 100%.
     - Quality Sweep test suite (`test_sweep_*.py`) passes 100%.
     - Variation auditor test suite (`test_dialogue_variation_auditor.py`) passes 100%.

## Mandatory quality principle

Achieved: 1 weak/repetitive family -> 10 natural, distinct, context-safe, grounded realizations across all active styles in Project Hoomans.

## Final completion condition

Final corpus audit reports:
`EXPAND_TO_10 buckets below 10 = 0`
All quality, translation, reachability, semantic-invariance, and regression gates passed cleanly.

