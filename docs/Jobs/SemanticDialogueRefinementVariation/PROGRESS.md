# Semantic Dialogue Refinement & Variation Expansion — current progress

**Parent goal status: IN PROGRESS.**

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

`MAX_PHRASES_PER_STYLE = 6`

This must be raised before the corpus can satisfy the requested minimum.

## Phase state

| Phase | State |
| --- | --- |
| P0 — audit / contract | **COMPLETE (planning)** |
| P1 — capacity + inventory tooling | **COMPLETE** |
| P2 — core conversation | **IN PROGRESS** |
| P3 — social | **NOT STARTED** |
| P4 — commands/tasks | **NOT STARTED** |
| P5 — events/combat | **NOT STARTED** |
| P6 — remaining corpus / exemptions | **NOT STARTED** |
| P7 — corpus-wide acceptance | **NOT STARTED** |

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

## Immediate Active Phase — P3: Social interaction refinement

Expand and refine all canonical social interaction dialogue shards to >= 10 meaningful, relationship-safe variants:
- **P3A**: Social Reactions (`content/social/reactions.json`: 11 families, 52 styles).
- **P3B**: Social Emotes (`content/social/emotes/reply.json`: 10 families, 18 styles; `content/social/emotes/conversation.json`: 1 family, 4 styles).
- **P3C**: Social Interaction & Director (`content/social/interaction/*.json`: scene adopters, memory acknowledge, argument deescalate/retaliate, topic redirects).
- **P3D**: Social Tool Replies (`content/social/tool_replies/*.json`: apology, comfort, compliment, flirt, hostile, insult, praise, reassurance).
- **P3E**: Social Apology (`content/social_apology.json`: 4 families, 16 styles).

Every eligible active style in these social shards must reach **>= 10 meaningful, grounded, context-safe phrase variants** with valid EN/TL parity.

## Mandatory quality principle

Do not turn:

`1 mediocre sentence → 10 mediocre synonyms`.

The goal is:

`1 weak/repetitive family → 10+ natural, distinct, context-safe realizations`.

## Completion condition

Final corpus audit must report:

`EXPAND_TO_10 buckets below 10 = 0`

plus all quality, translation, reachability, semantic-invariance and regression gates in HARNESS_ACCEPTANCE.md.
