# B phase — Grounded Personal Dialogue, Sparse Backstory, Knowledge & Dossier

**Approved product design / NOT IMPLEMENTED** as of 2026-10-20. Remote audit baseline: `263c132ea87678024cd81f8310bb85608dec28df`. Native PZ is user-owned. This phase follows the *recorded* C7A–C7G developer acceptance without rejecting those narrow test results. User's newer real Semantic Lab screenshot proves an additional out-of-sample error: `nice dress` returned generic clarification; `you got nice dress` produced `QUESTION / INVENTORY` at confidence 0.88 and sent `SemanticInventoryQuery`. A green earlier C7 suite is not acceptance of these phrases.

## Product goal

Provide natural, personal and consistent NPC offline Lua conversations from stable generated background, current verified world facts and remembered events. Let individual players gradually learn NPC histories through consent/disclosure and see *only discovered facts* in the existing NPC Dossier. Maintain extremely low ModData footprint by using the NPC's EXISTING identity seed, independently versioned backstory definitions, lazy resolution, sparse exceptions and existing Knowledge evidence. The same privacy/knowledge boundary governs optional PBrainZ prompts.

## Verified current source foundation

1. `PNC_ConversationMemory_Backstories.lua`: `Memory.GetBackstory(record, kind)` and `Memory.GetBackstoryProfile(record)` select weighted per-kind definitions by `identitySeed` and `tacticalClass`, using salted `PNC.Identity.Range`. A bounded 256-profile cache is runtime only. Existing source comment says seed facts are computed, while packed birth date is persisted.
2. `PNC_ConversationMemory_BackstoryContext.lua`: `Memory.BuildBackstoryFacts(record, limit, language)` builds up to 10 localized facts. Existing optional `PNC_PBrainZ_ContextPayload_DialogueFacts.lua` consumes this. Direct equivalent offline semantic disclosure to the server-owned knowledge registry was *not established in the audited code*; verify other call paths before implementing.
3. Existing `PNC.KnowledgeDescriptors / Providers / EvidenceSources / Resolvers` separate truth, player knowledge and evidence. `PNC_NPCKnowledge` persists `byCharacter[uuid].byNPC[npcID]` **only after interaction**. `Knowledge.CanDisclose` checks per-descriptor minimum familiarity and optional approval. `Knowledge.Disclose` calls the truth provider and records `direct_disclosure` evidence. Familiarity milestones record journal opportunities; they do NOT reveal descriptors.
4. `BuildPlayerSnapshot` and `PNC_KnowledgePresentation.BuildDossierRows` expose discovered values only. Dossier is already category/descriptor-driven. Existing `history` category exists; player-side UI never queries provider truth.
5. `docs/Systems/Persistence.md` contracts: seed-derived regeneration is lazy with independent revisions; server-only ModData, no global all-NPC scan, per-record dirty batching and no direct ModData broadcast. Its current supported 100 persistent NPC baseline is not a promise of 1000 simultaneously live AI NPCs.

## Invariants and precise ownership

| What | Canonical owner | Persist only |
| --- | --- | --- |
| Stable generated past | Existing identity seed + version-pinned Conversation Backstory definitions | Reuse existing seed; at most a small generation epoch or stable-ID exceptions if needed |
| Authored/contradiction override | Existing NPC persistence/identity owner | Sparse `kind -> stable backstory definition ID` or bounded override when genuinely different; NO full profile or paragraphs |
| Current residence, worn clothing, medical state, inventory | Existing game authority/domain owner | Existing mutable state; NEVER overwrite hometown because NPC moved |
| Subjective memories / event history | Existing Conversation Memory / Knowledge / event authority | Bounded event IDs/deltas, not complete transcripts |
| Player's learned NPC history | Existing server `PNC_NPCKnowledge` | Only discovered descriptors/evidence, keyed by player character UUID and npcID |
| Active question/topic/cooldown | Existing `SemanticDialogueContextState` / Relationships | Runtime/session by default; persist one bounded refusal lease only if repeated-save exploit actually proven |
| Dossier presentation | Existing server snapshot + client KnowledgePresentation | No extra authoritative store; client only receives authorized discovered facts |

Never create a second `NPCBackstories` global ModData root, a duplicated player/NPC truth matrix, a literal paragraph per NPC, full conversation transcription or a second gameplay/disclosure dispatcher.

### Seed determinism and catalog evolution

Current weighted selection computes `roll = Range(seed, "pnc:backstory:"..kind, 1, bucket.totalWeight)`, so changing weights/insertion order/totalWeight may reroll old selections. This is a **real migration risk**.

- In B1 pin a **backstory catalog epoch** independently from root NPC persistence schema. Prefer an existing generation-version field if one is already suitable; otherwise add the smallest genuinely necessary per-NPC epoch only when legacy replay cannot be guaranteed by stable published catalog selection.
- Old epoch must have immutable legacy selection tables/weights or targeted old selections pinned by *stable definition IDs* (not full narrative text). New NPCs may use new epoch.
- No blanket save reset, no reroll on dossier refresh, language switch, save/load or newly added backstory definitions. Recompute age/time-dependent presentation from canonical date and engine time; do not mutate historical birth date.
- If an old selected definition is deleted, do not silently substitute a new contradictory one; report unresolved legacy ID, preserve a compact fallback/upgrade policy and ensure previously disclosed historic knowledge is still presented truthfully.
- Test seed, class, epoch, definition order/revisions and authored overrides over reload and registry growth. Avoid inventing hashes or persistence field names until the source owner is audited.

### Disclosure thresholds and grace

Use existing `KnowledgeDescriptors.Register`, `Providers.Register`, `CanDisclose`, `Disclose`, evidence source and dossier snapshot mechanics, not a custom unlock service. **Suggested initial tuning ONLY** (verify against existing relationship balance before implementing):

| Category | Familiarity candidate | Additional policy |
| --- | --- | --- |
| name/basic intro | 0 | Explicit ordinary introduction, not full profile reveal |
| hometown/public personal background | 10 | Normal conversation opportunity, not automatic unlock |
| former job, hobby, education | 20–25 | May require a conversation about that topic |
| family/values/survival story | 35 | Personality/approval/refusal controls |
| tragedy/fear/private history | 50 + approval | Explicit willingness and privacy; refusal is valid |

Threshold only means **eligible to disclose**. It MUST NOT auto-record evidence, unlock all descriptor values on level-up or reveal a withheld fact through the client/PBrainZ. Existing direct disclosures create the learned record after valid server conversation lease and authoritative commit. An NPC saying "I'd rather not talk about that" is a recognized question with a privacy refusal, not an unknown-intent fallback. Rate limit repeated pressure using existing session/relationship cooldowns where possible, without new persistent counters per NPC/player.

### Value/evidence compaction

First integrate the existing Knowledge storage unchanged with compact stable descriptor IDs, enum/definition-ID values and bounded evidence. Measure actual serialized bytes per *interacted-with player/NPC pair*, not merely a per-NPC estimate. Evidence payloads and discovered values currently both may include a value: deduplicate ONLY if measured overhead warrants it, with a versioned resolver and explicit historic-value semantics. Do not delete evidence, override existing `direct_fact` resolver requirements or replace the current save schema from assumption. Real disclosures remain traceable and server-authoritative; absence of player record means unknown.

### Privacy and truth boundary

NPC can know its own past without the **player** knowing it. The server-side conversation planner may resolve candidate truth internally, but outgoing text, debug/non-admin worker records, client snapshots and PBrainZ payloads must contain only what policy authorizes for that target player. PBrainZ's existing bounded `BuildBackstoryFacts` path needs an outgoing **disclosure-filtered** projection; do not pass all hidden facts to an optional LLM and merely ask it not to reveal them.

Dossier must derive the Background/History section from the *same discovered descriptor snapshots* as conversation. Use `suspected` versus `confirmed` correctly; current player may retain last-known historical observations when mutable truth changes. Unrevealed facts are omitted from client snapshot. If the GUI shows generic unknown placeholders, never leak presence or nature of an NPC-specific hidden tragedy.

## Approved implementation sequence — one verifiable chunk at a time

**B0 — CURRENT ONE NEXT CHUNK: stop compliment/inventory collision, baseline backstory access.**
- In real Core+Hoomans worker reproduce `nice dress`, `you got nice dress` and `you got a nice dress` (social), `have you got a dress?` and `you got any bandages?` (inventory), plus ambiguous `you got a dress`, negation/quotes/third party and EN/TL. Capture competing candidates, match source, question evidence, chosen IR, actual reply and `SemanticInventoryQuery` dispatch.
- Correct existing social/inventory arbitration using recognized statement-vs-question cues, sentiment/evaluation/possessive context and safe uncertainty. Do NOT simply hardcode two phrases or raise all compliment priorities. A compliment triggers zero inventory/gameplay query; a genuine inventory question uses only the existing authorized path.
- Separately verify seed-derived `GetBackstoryProfile` with actual NPC identity and replay after worker/reload (read-only feasibility). Don't add Knowledge descriptors, extra ModData, backstory UI or invented personalized text yet.
- Pass relevant Lua worker, social/inventory/quest/preview EN/TL regression and `pz_verify`; record exact SHA and behavior trace. Only after acceptance advance to B1.

**B1 — deterministic biography consistency with near-zero storage.** Audit weighted registry stability, seeded selection and authored overrides; lock epoch/replay or smallest necessary pinned-ID delta, validate age/job/hometown and unique-NPC coherence across definition version/locale/save/reload. Compare ModData baseline byte counts; avoid rewriting entire record schema or eagerly creating overrides.

**B2 — existing backstory to existing offline fact provider.** Reuse `GetBackstoryProfile/GetBackstory`; register read-only provider mapping former_job/hometown/hobby/etc to typed fact fields with stable IDs. Separate hometown from mutable current residence and real bite status. Real worker must answer known and unknown variants; no network/LLM needed and no undisclosed client truth.

**B3 — Knowledge discovery, discretion and grace.** Add descriptors with categories/privacy/disclosure gates, server-authorized conversation lease, witnessed/gossip/direct evidence based on existing source types, refusal/cooldown controls and single-effect commits. Threshold eligibility never means knowledge automatically learned. MP A/B independent discovery, restart persistent, no fake relationship/quest actions; compare direct versus inferred confidences.

**B4 — dossier History/Background integration.** Existing descriptor-driven `PNC_KnowledgePresentation` renders discovered facts only with suspected/confirmed and translated labels. Demonstrate two player characters see different details for the same NPC; server snapshot omits undisclosed values, no seed/reconstruction on client, no secret leakage in popups, logs or raw responses.

**B5 — personal conversation continuity.** Explain own job/origin/family/hobby, follow up "Where?", "Do you miss it?", reason about actual event evidence; personality affects willingness/tone, NPC initiative only when appropriate, suppressed by danger/cooldown. Reuse existing ContextState/response plan and knowledge authority, no fabricated history, optional PBrainZ fact parity/filtered payload.

**B6 — storage/performance/compatibility gate.** Compare serialized ModData before/after for 0, 1, 10 discoveries across many abstract NPCs, including 100-NPC supported baseline and larger *synthetic* scale samples. Check save/load, lazy construction, cache hit/eviction, bounded time/memory, EN/TL, MP privacy, no per-tick loops or full-profile RPC. Run full real Lua/harness/compiler/doctor/Kahlua; ready for **USER-OWNED live PZ test** only when developer gates pass.

## Must-include realistic integration scenario

Same NPC, fixed seed and epoch, generated former nurse and hometown Rosewood (fixture-specific only). Player A has enough familiarity AND was explicitly told these, so dossier shows confirmed nurse/Rosewood. Player B has little familiarity and has not learned them, so snapshot and optional provider payload do not reveal them. Familiarity milestone for B grants **opportunity not knowledge**. Authoritative later current-settlement move changes *residence*, not *hometown*. Restart and add newer backstory catalog entries; established facts and scoped discoveries must remain correct. Unknown/unavailable/privacy denial get distinct truthful response plans.

## Acceptance and developer restrictions

Each phase reports repo/Core SHA, actual worker input→IR/competing candidates→NPC fact source→CanDisclose/result→response/persistent evidence→dossier snapshot→side effects, exact new runtime artifacts and true test numbers. Only claim runtime coverage when run; no giant JSON fixture campaigns or tests that only assert a mocked wrapper. No native PZ game launch, hosted MP, Steam Workshop installation/publish, user-account operations or Codex-native CUA dependency. Preserve previously accepted C7 implementation and all source ownership.
