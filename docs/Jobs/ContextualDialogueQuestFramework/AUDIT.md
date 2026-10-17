# Baseline audit — code evidence versus proposed features

**Source date:** 2026-10-18. **Remote main inspected:** a3eb2e4db553f9c03b7f66a6ff6717878e1668e0. This is a remote-source audit, NOT a fresh local worktree, live GUI click-through, native Project Zomboid run or hosted CI rerun.

## Implemented or source-verified foundations

| Evidence | What it establishes | What it does NOT establish |
| --- | --- | --- |
| tools/semantic_harness/README.md; worker.py; gui.py | Existing Tk/Python console and persistent worker load actual Project Hoomans/PsychopatzCore semantic modules; preview and turn observations include production facts | GUI CRUD/edit ergonomics or real in-game correctness |
| tools/semantic_harness/flow_editor.py | Canvas renders nodes/edges; selecting a node and changing response/accept/transition fields is implemented; drafts validate/register through Lua | Creating/deleting/dragging/linking nodes, rich code editor, persistent Lua export |
| tools/semantic_harness/tests/test_flow_editor.py | Tests author/register a new flow and route turns through real Lua; rejects unreachable graph node | User click-through; production restart-persistent authoring; quest completion |
| 42.20/media/lua/shared/PNC/Semantics/PNC_SemanticDialogueFlowRegistry.lua | Validates data-only triggers, accepted frames, nodes, slots, transitions and reachability; current defaults MAX_NODES=32, DEFAULT_MAX_FLOWS=32 | Context condition gates or quests as valid V1 flow fields |
| .../PNC_SemanticDialogueFlowKernel.lua | Has bounded active/suspended flow states, preview/commit lifecycle and speaker/addressee keys | Durable cross-session semantic memory of arbitrary commitments |
| client/PNC/Semantics/PNC_SemanticWorldContext.lua | Samples game time, weather, environment, and caches snapshots | Server-authoritative revalidation or NPC-local omniscience |
| shared/PNC/Semantics/PNC_SemanticDialogueSituation_Public.lua | Projects activity, needs, health, emotion, social context and world time/rain/fog/indoors | Quest-state projection |
| docs/Systems/ConversationBlocks.md | Existing separate Conversation Blocks gate API: skill/trait/personality/relationship/audience/time/history, composite all/any/not, locked choice modes, repeat policy, addon condition/effect handlers, server-owned effects | Those gates already being reused by new semantic flows |
| docs/Systems/SocialProfiles.md | Persistent NPC personality profile with compassion, sociability, forgiveness, bravery, materialism, aggression, loyalty and social style | A new quest-specific disposition or willingness model |
| docs/Systems/NPCKnowledge.md | Existing knowledge/evidence and bounded knowledge storage concepts | General open-ended, durable conversation-memory recall across all sessions |
| docs/Jobs/SemanticDialogueDecoupling/PROGRESS.md | Older job reports D6 READY FOR USER LIVE TEST and prior production-worker results | Current session's fresh runtime test results |

Additional quest-themed map marker/role strings occur in the repository, but search did not establish a standalone authoritative quest registry, journal/objective state machine or idempotent reward service. Treat **Quest domain as not yet proven implemented**; re-audit targeted files before writing it.

## Concrete present gaps

1. **Flow authoring UX:** graph drawing uses fixed two-column positions, only click-to-select; fields require manual transition IDs and JSON arrays; no node creation/removal, drag/drop, connect or code-first editor.
2. **Persistence:** Register draft is worker-local and disappears after restart; saved draft is JSON, not packaged production Lua. Avoid a separate runtime JSON dialogue engine.
3. **Gate mismatch:** mature Conversation Blocks conditions and new semantic flows use different contracts. Design an adapter/shared pure evaluator rather than blindly grafting fields or duplicating rules.
4. **Context continuity:** fields for current/previous topic and active/suspended state are present, but safe cross-session promises, speaker-scoped references and provenance-aware retrieval are not yet demonstrated end-to-end.
5. **Quests:** no source-verified canonical server-owned quest lifecycle/reward pathway in this audit.
6. **Acceptance:** no new job-specific production Lua traces, UI click-through, native game acceptance, CI or performance measurements have been executed.

## Specific first inspection targets

- Core and Hoomans parser/candidate/flow router public contracts and required upstream revision in the actual local pair.
- Conversation Blocks RegisterConditionHandler and gate evaluation/validation implementation and compatibility with flow preview/commit.
- Flow Registry.NormalizeNode and Kernel Preview/Commit: side-effect-free evaluation placement and scope, including special target semantics.
- Current world context provider's observation scope/client-local nature; server-side authoritative fact sources.
- Existing knowledge/memory APIs and conversation obligations: prove reuse boundary before creating storage.
- Existing quest-like UI markers/roles/jobs: do not mistake labels for quest infrastructure.

## Evidence labels

- **Source-verified:** claims above for named remote files.
- **Documented but not rerun:** earlier job's unittest counts, X11 launch probe, EN/TL semantic traces.
- **Planned, not implemented:** shared condition bridge, cross-session context, quest domain, editor CRUD/code round trip.
- **User-owned not tested here:** native SP/MP and Workshop/install parity.

Do not inflate an agent's historical "D3 complete" into this goal's stronger requirement for full graph CRUD, persistent authoring, code sync and contextual gating. These are additional acceptance outcomes, not grounds to erase historical D3 evidence.
