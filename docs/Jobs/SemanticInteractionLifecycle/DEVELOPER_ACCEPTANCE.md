# Semantic Interaction Lifecycle — Developer Acceptance Evidence

**Checkout:** existing `main` only

**Baseline:** `e8c04b4fb2139be315253f12e0f06a5dfa3fc70f5`

This is the developer-side evidence record. Native Project Zomboid SP/MP launch and final live acceptance remain user-owned.

## Production-Lua and worker scenarios

| Required behavior | Evidence |
| --- | --- |
| Typed/button/emote/headless meaning converges | `pnc_semantic_interaction_lifecycle_smoke.lua`, `test_semantic_interaction_lifecycle_p1.py`, and `test_semantic_interaction_lifecycle_acceptance.py` |
| NPC speech creates a reply beat with provenance | Lifecycle smoke, greeting/social-event/emote smokes, worker snapshot acceptance |
| Topic interruption and resume | Lifecycle smoke and P1 worker test |
| UI transcript rows are not semantic state | Worker response-window/export tests assert bounded semantic fields and no transcript/raw/rendered text |
| Meaningful multi-day suspend/rehydration | P1 worker close/resume at hour 120 and production P14 rehydration test |
| Trivial interaction leaves no pair | Lifecycle smoke and worker acceptance |
| Significant facts/commitments/memories remain compact | P1 worker promotion assertions and response-window inspectors |
| 200-turn conversation remains bounded | P1 worker test asserts 12 recent turns and capsule below 12,000 bytes |
| Multiple players isolate the same NPC | P1 sparse multiplayer test and Lua private projection assertion |
| Hundreds of NPCs do not allocate Player × NPC state | P1 stress test: 400 NPC identities and 2,000 trivial turns leave zero pair records |
| Shared events are referenced once | P1 shared-event test and social/Project A-Life bridges |
| Dormant NPC lifecycle work is zero | Lua and worker metrics assert `dormantTickWork == 0`; `Advance` performs no scan |
| Network/private context remains bounded and isolated | Server projection path, private projection smoke, authority guards and full regression suite |
| P14 source save remains immutable | `test_production_faction_rehydration_p14c.py` compares the source snapshot before/after working-world lifecycle operations |

## Commands and results

```text
lua tests/pnc_semantic_interaction_lifecycle_smoke.lua                         PASS
lua tests/pnc_semantic_interaction_persistence_smoke.lua                       PASS
lua tests/pnc_social_greeting_smoke.lua                                        PASS
PZ_TEST_CORE_RUNTIME=42.20 lua tests/pnc_social_events_smoke.lua               PASS
lua tests/pnc_conversation_farewell_smoke.lua                                  PASS
lua tests/pnc_vanilla_emote_interactions_smoke.lua                              PASS
lua tests/pnc_llm_tool_reply_catalog_smoke.lua                                  PASS
python3 -m unittest tools.semantic_harness.tests.test_semantic_interaction_lifecycle_p1 \
    tools.semantic_harness.tests.test_semantic_interaction_lifecycle_acceptance -q
python3 -m unittest discover -s tools/semantic_harness/tests -p 'test_*.py' -q
python3 tests/run_tests.py
```

Recorded results: focused lifecycle worker tests passed 10/10; the full Lua suite passed 873/873 in 5.26 seconds; and the full Python suite exited successfully. Focused P14 rehydration coverage is included in the full Python suite and was also run directly during verification.

```text
python3 /home/psychopatz/Desktop/Projects/Zomboid-devSkills/.agents/skills/pz-verify/scripts/pz_verify.py \
    --mod-dir Contents/mods/ProjectHoomans --kahlua \
    --severity ERROR --no-snippets                                         PASS
```

The verifier scanned 3,094 files, reported zero Kahlua errors and zero warnings. `luac -p` passed for the changed production Lua files, and `git diff --check` passed.

## Authority and fixture boundary

The Semantic Lab worker invokes production Lua for envelope construction, lifecycle mutation, compaction, expiry, projection, persistence import/export and metrics. Python provides transport, isolation, scenario driving and presentation only. No Python gameplay interpreter or replacement memory model was introduced.

## Intentionally unrun

Codex did not launch or restart Project Zomboid, perform native SP/MP acceptance, mutate the user's source save, or publish to Steam Workshop. Those are the final user-owned acceptance actions.
