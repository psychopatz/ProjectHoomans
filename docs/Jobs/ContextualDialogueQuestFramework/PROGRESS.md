# Contextual Dialogue & Quest Framework — CURRENT Progress

**Updated:** 2026-10-20

**Parent goal:** IN PROGRESS — complete V1–V5 on the existing `main` branch.

**Documentation baseline:** `556bdd7a57a7` (`main`). Core and other dependency
SHAs are recorded at the time of each acceptance chunk; native Project Zomboid
SP/MP, live servers, installation and Workshop publishing remain user-owned.

## Preserved foundation

B0–B6, H0–H4 and F1–F4 remain the preserved implementation baseline: identity-
seeded NPC backstories, sparse Knowledge/Dossier/PBrainZ projections, the typed
`semantic.interaction_spec.v1` compiler and writer, generated EN/TL catalogs,
the existing Core/Hoomans Lua worker, and the existing Semantic Lab GUI.

Historical F1–F4 acceptance evidence remains historical; it is not being
repeated as a substitute for the V1–V5 requirements.

## V1 — reusable visual CodeBlocks graph

**Status: IMPLEMENTED and developer-verified; next chunk: V2 localization.**

Implemented in the existing Semantic Lab and CodeBuilder:

- declarative typed ports and connection contracts for registered blocks;
- add, remove, configure, connect and disconnect graph operations over the
  canonical `semantic.interaction_spec.v1` source;
- deterministic graph normalization/fingerprinting attached to existing
  generated definitions, without a second compiler or executable Lua path;
- cycle, orphan, invalid-port and unsafe capability wiring rejection;
- effect-free preview and explicit-approval-only generation;
- one Studio workflow for both NPC backstory and registered capability graphs;
- legacy `semantic.codeblocks.v1` action-flow compatibility preserved.

Developer evidence from baseline `556bdd7a57a7`:

- `python3 -m unittest tools.semantic_harness.tests.test_interaction_spec tools.semantic_harness.tests.test_v1_visual_authoring tools.semantic_harness.tests.test_codeblocks tools.semantic_harness.tests.test_semantic_blocks tools.semantic_harness.tests.test_conversation_inspector tools.semantic_harness.tests.test_flow_editor` — **33 passed**;
- V1 worker proof — **1 passed**: previewed both graph kinds with zero writes,
  generated distinct Lua/EN/TL assets after approval, restarted an isolated
  real Core+Hoomans Lua worker, received `I worked as farmer before all this.`
  for the backstory, and received `Okay, I will follow you for V1.` for the
  authored registered `FOLLOW` response with the existing action dispatch;
- Xvfb/Tk GUI construction smoke — **exit 0**, `workflow_gui_constructed 15`;
- Xvfb/Tk graph-edit smoke — **exit 0**, `workflow_gui_graph True 4 3`;
- `git diff --check` — **exit 0**.

The V1 production/test changes are ready for the bounded V1 commit. After that
commit, continue immediately with V2: consolidate authored fact-value
localization through PsychopatzCore `PsychopatzCustomTranslationManager`,
Project Hoomans `PNC.Translation`, and the existing catalogs/manifests while
preserving legacy TextLoader consumers.

## Remaining mandatory chunks

- **V2:** Core-backed localization, EN/TL switching, dynamic fact substitution,
  fallback and privacy diagnostics in the real worker.
- **V3:** personality-, relationship-, privacy- and context-aware disclosure
  through the existing server-authoritative Knowledge/Dossier services.
- **V4:** production-serializer actor/Knowledge/combined persistence metrics,
  synthetic 100/1,000 population measurements, and readable graph-to-effect
  Conversation Inspector projection.
- **V5:** end-to-end Semantic Lab Studio → approved generation → worker restart
  → conversation → Knowledge/Dossier/multiplayer privacy → graph regeneration
  behavior-change proof, plus focused/full developer checks.

No `GOAL_PROMPT.md` has been created or modified.
