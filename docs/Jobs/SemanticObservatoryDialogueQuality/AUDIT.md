# Source audit and initial baseline

**Classification:** code-inspected at ProjectHoomans main 0e2d5a23a36badef3a61d35c4a6cdc2d1336f017 on 2026-10-26; historical acceptance and previous focused test evidence differentiated below. No Observatory functionality is claimed implemented.

## Verified existing implementation

| Area | Inspected file(s) | Finding |
| --- | --- | --- |
| Studio UI | tools/semantic_harness/studio/workflow.py; studio/interaction_explorer_pane.py; ui/studio_surface_builder.py | Existing typed composition, search, preview, explicit generation approval, graphical interaction explorer; main workflow overemphasizes manual creation/JSON. |
| Real worker catalog | tools/semantic_harness/lua/worker/FlowEditor.lua | FLOW_CATALOG exposes flows, triggers, capabilities, policy, generated coverage and response pool IDs with variant counts. It does **not** expose full per-variant conditions/text/selection explanations in the response pool catalog. |
| Agent access | tools/semantic_harness/cli.py; runtime/worker.py | --no-gui, --jsonl, --case, --input, --audit, --search-datasets, --list-blocks, workflow preview/generate, etc. No dedicated compact inspect-by-response-pool or coverage matrix command established. |
| Inspection | tools/semantic_harness/inspection/conversation_inspector.py; conversation_inspector_response.py | Real-worker acceptance chain, selected flow, final response, execution/effects and grounded fact provenance already projected; needs direct response-variant and source mapping. |
| Response rules | 42.20/media/lua/shared/PNC/Semantics/PNC_SemanticDialogueResponseCatalog_Core.lua; _Selection.lua; _Registration.lua | Pool ID and variant normalization, conditions, priority and specificity selector, bounded last choice tracking. MAX_POOLS=256, MAX_VARIANTS=16, MAX_LAST_VARIANTS=256, fallback text capped at 256 chars. |
| Content ownership | 42.20/media/lua/shared/PNC/Semantics/SemanticDialogueResponseCatalog/*.lua; _Generated.lua; codebuilder/sources/*.json; common translation assets | Actual authored Lua pools coexist with generated/reviewed definitions and canonical translation assets. A new editable content database would compete with these owners. |
| Regression foundation | tools/semantic_harness/tests/test_conversation_inspector.py; test_contextual_runtime_graph_p11f.py; test_codebuilder_consolidation.py; test_whats_up_semantic_response_p12h.py | Prior focused audit at the same HEAD ran 23/23 passing with tools/semantic_harness/.venv/bin/python (3.12); default Homebrew Python 3.14 could not import _tkinter. Record as previous-run evidence, not current implementation acceptance. |

Current repo root policy was read; root AGENTS.md permits a job-local roadmap and chat-only /goal, prohibits new branches, destructive Git changes, native PZ control and Workshop publication without authorization. At job creation, main was clean and synchronized with origin/main (0 ahead / 0 behind after explicit fetch).

## Concrete unimplemented gaps

1. No efficient paginated read-only per-variant catalog from **actual loaded** production response registry; present FlowEditor returns pool ID and count only.
2. No authoritative selector explanation reporting matching/failed conditions, score, tie-breaking, repeat history and selected ID while keeping selection side-effect-free.
3. Source provenance incomplete: catalog names/route labels are not a guaranteed owning Lua path, generated source entry or translation key. Must report UNKNOWN instead of guessing.
4. No systematic context-coverage/repetition matrix with explicit untested vs unreachable distinctions, negative/adversarial grounded cases and EN/TL parity.
5. Headless agent entrypoint and Studio are not yet two presentations of the proposed focused diagnostics/review contract.
6. No tested, isolated proposal-review integration for ChatGPT/Codex-authored response variants against the same Lua registry and canonical CodeBuilder writers.

## Compatibility issues to verify before edits

- The active Lua registry has 16 variants per pool; broadening it requires measured memory/load/startup and anti-repetition analysis, not an unconditional limit increase.
- Selection currently scores priority*100 + specificity, hashes tied best candidates and rotates away from the last selected candidate. Explain mode must reflect **exactly** this behavior without mutating history.
- Pool conditions include world/time/weather, wellbeing/health, relationships, persona and social state. Missing values must not be invented or normalized to a known game fact.
- Authored plan.turns and translation fragments can carry semantic actions/offers; text-only modifications must not silently rewrite plan, eligibility, disclosure or authority.
- Existing Studio consolidation doc notes a packaging-path discrepancy between generated common/media/translation output and root AGENTS.md guidance. Audit actual loader conventions before any planned output-path change; this job does not authorize migration by assumption.
- No universal static parser of handwritten Lua should become a false authority; prove source origin via safe registration/manifest provenance or admit unknown.
- Avoid temporary staging directories anywhere under watched media/, even for draft-only changes.

## Existing documentation not to duplicate

- docs/Jobs/ContextualDialogueQuestFramework/SEMANTIC_STUDIO_CONSOLIDATION.md
- docs/Jobs/ContextualDialogueQuestFramework/HARNESS_ACCEPTANCE.md
- docs/Jobs/ContextualDialogueQuestFramework/DATASET_CONVERSATION_PIPELINE.md
- docs/Jobs/SemanticInteractionLifecycle/PROGRESS.md

**Audit conclusion:** preserve all accepted Lua/CodeBuilder/Studio/worker infrastructure. Build an observability and measurable quality layer **on top**; this is a new product goal, not evidence that old Studio V1–V5 acceptance failed.
