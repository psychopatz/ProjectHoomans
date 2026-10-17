# Semantic Dialogue Orchestrator — ordered implementation roadmap

State: **PLANNED** (source audit only). Every gate remains open until the assigned agent records concrete tests and revision evidence in `PROGRESS.md`. Do not retroactively relabel the separate ContextualSemanticIntelligence job's earlier achievements.

## Phase 0 — real reproduction and narrow containment (ACTIVE)
0A. Use current real-Lua Semantic Lab, verified dependency SHAs, the exact reported transcript: NPC demands player name -> player asks `are you okay` -> NPC asks back -> player says `im fine thanks`. Test punctuation/case, `I'm fine, thank you`, explicit true/false identity, interruptions, and a non-identity response. Capture candidate IR, policy branch, pending identity state, request/transport, server-mocked/authoritative relationship before-after. Compare current live screenshot with trace, noting mocked boundaries.
0B. Fix only confirmed effect-bearing collision in Core/Hoomans appropriate owner; prohibit unintended identity requests/evasion during safe topic interruption. Keep genuine explicit identity validation and existing server gates. Add real-worker regression; no new flow engine yet.

**Gate:** screenshot scenario behavior passes, identity side effects absent for non-identity replies, explicit identity events still accepted/validated, preview idempotent, no broad regression, native SP/MP status explicit.

## Phase 1 — candidate semantics and eligibility
Introduce bounded candidate inspection/typed-slot validation with backwards-compatible Core API only if justified by Phase 0. Add Hoomans context eligibility and explainable rejection trace. Exact first, fuzzy conservative; ambiguity clarifies and cannot dispatch a command.

**Gate:** same ambiguous input produces explainable candidates and correct interpretation under differing contexts; valid unusual names safely handled by explicit/clarification path.

## Phase 2 — minimal reusable statechart kernel
Register flows with IDs, trigger frames, nodes, transitions, bounded context, suspend/resume/cancel/finish. Wrap around existing policy, do not replace command security, dialogue state or response catalog.

**Gate:** identity interruption by wellbeing, resumed identity, topic change, repeated preview and speaker isolation pass real-worker tests.

## Phase 3 — move two real flow modules
Migrate identity and wellbeing onto flow registry; preserve old response keys, translations and identity authority; remove superseded branches only with matching regression evidence.

**Gate:** add/change one branch locally without editing central switch and pass old identity/wellbeing/reaction cases.

## Phase 4 — authoring and collision instrumentation in Semantic Lab
Expose production candidate list, reasons, flow graph/node/transition and relation/transport deltas. Add a **registration/validation workflow** (code modules remain source of truth), coverage on shadowed/unreachable/duplicate flow rules, and scenario run tools.

**Gate:** a developer/agent can register a small test flow and debug it in actual production worker, with observable transitions and no JSON-only mock success.

## Phase 5 — compositional response plans
Use authored typed dialogue acts and localized grammatical templates, compatible with current conditional response pools and variation/recency guards. Keep no-context fallback and optional PBrainZ parity.

**Gate:** coherent two/three-act replies in EN/TL, correct slot formatting and context facts; no invalid sentence concatenations.

## Phase 6 — incremental integration
Move social/apology/offer/gossip/trading and command-related flows only where evidence justifies separation. Preserve authoritative task, identity, gift and MarketSense decisions, multi-speaker obligations and optional PBrainZ. Do not perform bulk catalog rewrite.

**Gate:** existing social/action regression suite and cross-domain real-worker tests pass.

## Phase 7 — native acceptance + performance
Controlled Project Zomboid Build 42 singleplayer/multiplayer proof: UI/replies, actual authoritative identity effect, queue/lifecycle, save/rejoin, two NPCs, overhead, no per-tick parsing or unbounded memory.

**Gate:** runtime evidence, exact game/mod/Core versions, failure cases and regressions documented. Only then mark maintenance-ready.

## Next-chunk rule
Exactly one Next Chunk appears in `PROGRESS.md`. Complete/verify it, update ledger with precise revision and tested commands, and only then advance. A success in the previous job's synthetic harness is not automatic completion here.
