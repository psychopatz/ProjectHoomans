# Contextual Dialogue & Quest Framework — CURRENT Progress

**Updated:** 2026-10-19, documentation-only phase transition; no new production Lua/GUI implementation or runtime test in this commit.
**Remote audit baseline:** `93cbb77498d8d35ded43d3594f59147d71a666e9` on `docs/contextual-dialogue-quest-framework-20261018`, PR #4 OPEN/unmerged at inspection. Local Codex checkout/upstream/parallel work must be reconciled before changes.
**STATUS:** **C7 CONVERSATIONAL COMPETENCE — IN PROGRESS**, NOT YET READY FOR USER LIVE TEST **for this expanded goal**.
**ONE NEXT CHUNK:** **C7A — Real-worker conversation baseline and reusable clothing-compliment + NPC bite-status question vertical slice.**

## Accepted historical foundation (preserved, don't reimplement)

Prior R0A–R5B developer work accepted INSULT trace, Interaction Explorer, `semantic.interaction_spec.v1` composition/CodeBuilder generated Lua, Studio/Simulation, bounded reviewed WordNet (29 aliases/91 forms for 14 concepts), limited MASSIVE/SGD records, contextual movement references, exact Worker Tk/source generation and repaired older semantic Lua failures. The previously reported **218/218 Python harness**, **16/16 compiler**, **68/68 Lua semantic smoke** passes belong to the prior checkpoint; not rerun today. Full prior PROGRESS is archived verbatim in `HISTORY_R0_R5B_20261019.md`. No claim the new conversational gap is accepted.

## New product evidence

User-shared current Semantic Lab GUI conversation: `do you have any news` → `I haven't heard any news lately.` (recognized gossip but no initiative); `wait here` → accepted STAY (must retain); `where do you live exactly` → generic clarification; `have you been bitten` → generic clarification; `i like your dress` → generic clarification. These are **user screenshot observations**, not a fresh worker rerun at this exact source SHA.

Read-only source confirms the complimentary social templates exist but `COMPLIMENT_FEATURE` excludes dress; `BITTEN` exists but an inspected phrase is a third-person gossip event, not a direct addressed medical-history inquiry. The local response question resolver is specific-subject based (TIME/DATE/WEATHER/IDENTITY/RELATIONSHIP_STATUS/ACTIVITY/WELLBEING/NEEDS/QUANTITY/LOCATION/SEEN), and existing ResponsePlan/ContextState has infrastructure but not broadly open-ended spontaneous talk. FlowGraph defaults to gameplay command/quest result nodes, not a full interpretation/explanation tree.

## C7A: exactly what to do next

1. Check actual local Hoomans/Core HEAD, dirty state, parallel agent ownership and source/translation paths. Read AGENTS + job docs; `PROGRESS.md` LAST.
2. Run a **real production Lua worker** with appropriately configured NPC/world facts and reproduce the exact five screenshot utterances as one multi-turn scenario. Record IR candidates, actual semantic branch/flow, fact availability/provenance, actual response plan/final visible text, context transitions and side effects. Include positive and adversarial rephrasings; avoid interpreting a single screenshot as a new code-level proof.
3. Fix only two *reusable* target deficiencies first: (a) apparel/appearance compliment recognition + appropriate existing social response for multiple natural variants, with negative and unrelated-text protection; (b) directly addressed bite-status question understanding and actual NPC medical-fact owner/unknown response, distinct from gossip about someone else. Source must not assume no bite without medical evidence. Do not hardcode one literal phrase per case or invent unregistered provider data.
4. Assert original `wait here` still dispatches exactly once and no change to gossip/no-news truth, INSULT/THREAT, command/quest/gift authority, preview purity or TL fallback. Where relevant update existing Simulation inspector's last-turn *explanation* (not another UI tab), distinguishing unknown semantic intent vs unknown world fact.
5. Test actual new worker final NPC text and EN/TL, Core IR with positives/negatives, full relevant semantic smoke, focused Python harness/compiler, doctor/Kahlua syntax/pz_verify, deterministic compiled artifacts where changed. Record executed counts, failures, repo/core SHAs and exact transcript/side effect evidence; if no real bite-status owner exists, document the gap and preserve truthful unknown response rather than fabricating a source.
6. Commit bounded implementation/tests/progress to checked authorized branch with safe expected state. If accepted, set ONE Next Chunk **C7B**; else keep C7A open with precise repro and blocker.

**No user-native game test is required to finish C7A**. No Codex PZ launch, multiplayer hosting, Workshop publishing/install. Source docs and acceptance details: `CONVERSATIONAL_COMPETENCE_C7.md`.
