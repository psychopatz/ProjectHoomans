# Semantic Interaction Lifecycle — Developer Acceptance Evidence

**Checkout:** existing `main` only

**Baseline:** `e8c04b4fb2139be315253f12e0f06a5dfa3fc70f5`

This is the developer-side evidence record. Native Project Zomboid SP/MP launch and final live acceptance remain user-owned.

## Production-Lua worker scenarios

| Required behavior | Evidence |
| --- | --- |
| Typed/button/emote/headless meaning converges | Lifecycle smoke, focused P1 worker tests, and acceptance worker tests |
| NPC speech creates reply-beat provenance | Lifecycle smoke plus greeting, social-event, emote, and worker snapshot acceptance |
| Topic interruption and resume | P1 lifecycle worker tests |
| UI transcript rows are not semantic state | Response-window/export assertions inspect bounded semantic fields without transcript/raw/rendered text |
| Meaningful multi-day suspend and rehydration | Close/resume at hour 120 plus production P14 rehydration coverage |
| Trivial interaction leaves no pair state | Lifecycle acceptance worker test |
| Significant facts, commitments, and memories remain compact | Promotion assertions and response-window inspectors |
| 200-turn conversation remains bounded | Lifecycle worker test asserts bounded recent-turn capsule and compact export |
| Multiple players isolate the same NPC | Sparse multiplayer private-projection assertions |
| Hundreds of NPCs do not allocate Player × NPC state | 400-NPC/2,000-trivial-turn stress assertion |
| Shared events are referenced once | Canonical shared-event and social/Project A-Life bridge assertions |
| Dormant NPC lifecycle work is zero | Worker metrics assert `dormantTickWork == 0`; `Advance` performs no scan |
| Network/private context remains bounded and isolated | Server projection, private projection, and authority-guard coverage |
| P14 source save remains immutable | Save-backed rehydration test compares source bytes before and after working-world operations |

## Commands and results

```text
python3 -m unittest tools.semantic_harness.tests.test_semantic_interaction_lifecycle_p1 \
    tools.semantic_harness.tests.test_semantic_interaction_lifecycle_acceptance -q
PASS: 10 tests

XDG_STATE_HOME=<temporary> xvfb-run -a \
    python3 -m unittest discover -s tools/semantic_harness/tests -p 'test_*.py' -q
PASS: 517 tests, 0 failures, 0 errors

python3 tests/run_tests.py --lua lua5.3 --jobs 4 --timeout 30
PASS: 873/873 in 5.46s (4 workers)

find Contents/mods/ProjectHoomans/42.20/media/lua -type f -name '*.lua' \
    -print0 | xargs -0 -n1 luac5.3 -p
PASS

python3 /home/psychopatz/Desktop/Projects/Zomboid-devSkills/skills/pz-verify/scripts/pz_verify.py \
    --mod-dir Contents/mods/ProjectHoomans --kahlua \
    --severity ERROR --no-snippets
PASS: 3,094 files scanned; 0 Kahlua errors and 0 warnings

git diff --check
PASS
```

The full Python suite includes the P14 save-backed immutability coverage and the production-Lua lifecycle acceptance. The Semantic Lab uses production Lua for envelope construction, lifecycle mutation, compaction, expiry, projection, persistence import/export, and metrics; Python supplies transport, isolation, scenario driving, and presentation only.

## Intentionally unrun

Codex did not launch or restart Project Zomboid, perform native SP/MP acceptance, mutate the user's source save, or publish to Steam Workshop. Those are final user-owned acceptance actions.

## P10/P11 corrective acceptance — 2026-10-25

The corrective implementation evidence is separate from the historical P0–P9
record above:

```text
python3 -m unittest tools.semantic_harness.tests.test_contextual_talk_parity_p11j -q
PASS: 22 tests, including the large saved-world Open-response bound

The Open response now contains only the bounded production Conversation
projection and no duplicated configured/inspector snapshot. The regression
keeps a 120 KiB save-backed payload below the 256 KiB worker boundary.

python3 -m unittest tools.semantic_harness.tests.test_legacy_semantic_authority_p11 -q
PASS: 11 tests

python3 -m unittest \
    tools.semantic_harness.tests.test_contextual_runtime_parity_p11a \
    tools.semantic_harness.tests.test_contextual_runtime_parity_p11b \
    tools.semantic_harness.tests.test_contextual_runtime_parity_p11c \
    tools.semantic_harness.tests.test_contextual_runtime_parity_p11d \
    tools.semantic_harness.tests.test_contextual_runtime_parity_p11e \
    tools.semantic_harness.tests.test_contextual_runtime_graph_p11f \
    tools.semantic_harness.tests.test_contextual_runtime_speech_p11g -q
PASS: 29 tests

python3 -m unittest tools.semantic_harness.tests.test_semantic_dialogue_flows \
    tools.semantic_harness.tests.test_contextual_speech_behavior_p8b \
    tools.semantic_harness.tests.test_semantic_interaction_lifecycle_p1 \
    tools.semantic_harness.tests.test_semantic_interaction_lifecycle_acceptance -q
PASS: 34 tests

python3 tests/run_tests.py --lua lua5.3 --jobs 4 --timeout 30
PASS: 874/874

changed Lua syntax validation
PASS: 44 changed Lua files parsed with luac5.3

changed Python compilation
PASS: 27 changed Python files passed py_compile

python3 /home/psychopatz/Desktop/Projects/Zomboid-devSkills/.agents/skills/pz-verify/scripts/pz_verify.py \
    --mod-dir Contents/mods/ProjectHoomans --kahlua \
    --severity ERROR --no-snippets
PASS: 3,096 files scanned; 0 Kahlua errors and 0 warnings

git diff --check
PASS

final codebase-memory coverage
PASS: refreshed full index has zero skipped/partial parses; all 78 changed/
      untracked source, worker, test, and active-goal documentation paths
      report no_recorded_issue
```

These checks prove the semantic authority boundary and native Conversation
projection with production Lua. A read-only production save selection at
`/home/psychopatz/Zomboid/Saves/Sandbox/2026-10-22_08-59-28` opened through the
same worker seam with a 64,285-byte response, six exact production-presented
rows, and no duplicated snapshot payload. The broad historical discovery suite
was attempted separately, but its oversized terminal report was not retained;
the P10/P11-scoped production-worker modules above are the relevant corrective
regression gates and are green. Native Project Zomboid SP/MP acceptance remains
user-owned.
