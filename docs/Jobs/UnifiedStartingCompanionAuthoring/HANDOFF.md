---
handoff_schema: 2
target_repo: "/home/psychopatz/Zomboid/Workshop/ProjectHoomans"
branch: "main"
updated_at: "2026-11-18T14:22:25.594662Z"
state: "USER_ACCEPTANCE"
parent_status: "IN_PROGRESS"
phase: "P5R7"
chunk: "P6 native scoped dice, live constraints and skin/gender retest"
retrieval_tier: "verify"
codebase_memory_indexed_commit: "9fdfc7b63354f6d29912ff90b0d98c5edffdeb8c"
checkpoint_mode: "committed_handoff"
phase_commit: "self"
phase_commit_phase: "P5R7"
phase_commit_message: "phase(P5R7): add scoped tab dice and relationship constraint explanations"
phase_commit_vector: "project-hoomans=self;psychopatz-core=7c91517b1f37d042e716eb88d1fb52bca38908c2;dynamic-trading=0fcf35196452db0675788167df205aec09748caa"
phase_residual_vector: "project-hoomans=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f;psychopatz-core=cd983a60f5034d1fabb607073b599a86d6f77b72113b2a040ea7cc081019b007;dynamic-trading=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
residual_worktree_fingerprint: "a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
---


# Session Handoff

P5R7 adds per-tab dice in the same shared editor. Bio varies names/nickname and
retains chosen body/archetype; Appearance varies editable skin/hair/voice;
Attributes uses loaded compatible skills/traits without companion-selection
traits; Loadout materializes exact clothing/gear. Unrelated scopes and inherited
values stay stable. Transactions validate before a single canonical commit;
rejected generation preserves pending text. Random policies stay absent from
companion selectors.

Relationships now explains NPC/player roles, originating trait and actual
constraints. Semantic backstory generation is TODO; its dice is visibly disabled.
Locks appear only for real constraints and dynamically explain surname/family/
orientation. Policy reads current context: Friend/bisexual Lover gender editable;
fixed and straight/gay rules authoritative. Wire sanitization retains partner sex
intent for authoritative contextual resolution.

Manual appearance commits precede repaint; locked callbacks cannot mutate drafts.
Native skin texture selection clears stale custom RGB from the preview cache.
No native rendering/input/audio success is claimed.

`TEST_VERIFIED`: **58/58** focused; **1052/1056** full suite, with the same four
prior scene-route/context-scene/population-initialization/Debug-Hub-translation
failures. `STATIC_ONLY`: **32** Lua syntax, **22** production Kahlua, JSON,
**26** new/one updated EN/TL keys, parity/reference/whitespace checks. Coverage
checked for 39 Hoomans/two Core evidence paths; dirty/new source read directly.

Next is user-owned P6: test all page dice and scope stability, repeated skin and
gender edits, live orientation/surname constraints and tooltip visibility,
relationship wrapping and saved presets across fonts/sizes. Continue prior
browser/voice/SP/MP/co-op/finalization matrix. No game launch/control, push or
Workshop publication. Preserve unrelated work. The phase helper records the exact owned local commit and verifies its checkpoint.

Concurrent semantic/test commits advanced main to `77994e19dccc5a4d94579b480fd24f3db8e68979` during
this repair. Their committed paths are disjoint from all 39 phase-owned paths;
those commits are preserved. Final focused/full validation ran on that state.
