# Contextual Dialogue Persona & Choices — Current Progress

**Updated:** 2026-10-22  
**Parent status:** IN PROGRESS — documentation/audit complete; implementation not started.  
**Remote source audit baseline:** ProjectHoomans `main` at `765bc4076ab82ec2c1eca6ca52cef1c6bf177597`.  
**Dynamic Trading source inspected:** `5b97302e39c482682f4fed0c083ad6764b9eee41`.  
**Local worktree status:** not observable from this ChatGPT GitHub audit; agent must verify before implementation.

## Verified foundation

Source audit confirms:

- existing typed semantic suggestions already use stable candidates/frames, localized label + utterance keys, privacy predicates, stale/duplicate protection, and the existing DialogueInput/action authority path;
- active-flow offers, response-plan offers, authored Conversation choices/root already supply dynamic candidates;
- the current static semantic/capability catalogs remain centralized in `PNC_SemanticDialogueSuggestions.lua`;
- `PNC_SemanticDialogueInput_ContextProjection.lua` already projects relationship, knowledge, gossip, flow/topic, world/situation and entity context but does not yet expose one canonical complete actor/persona/speech context;
- persistent Social Profile, NPC Traits and directed Relationships already own the needed personality/social data;
- Semantic Lab scenario state already supports traits, relationship, actor authority, health/activity and language/runtime fields;
- Dynamic Trading already has portable conversation/NPC-foundation adoption material suitable for a later trader provider.

These are source-level findings. This documentation task did not rerun Lua/Python suites or native Project Zomboid.

## Known product gap

The existing systems need to be connected, not duplicated:

1. modularize choice definitions/providers;
2. project canonical actor conversation context;
3. derive transient speech style;
4. realize semantic responses/choices through localization-safe variants;
5. apply contextual ranking/privacy without changing authority;
6. integrate Dynamic Trading through the provider seam;
7. expose/tune/test all of it in the real Semantic Lab.

## Current mandatory phase

**P0 — Current-path contract baseline**

### Exact Next Chunk

On the user's actual local checkout:

1. read root `AGENTS.md` and this job;
2. verify ProjectHoomans/Core/DynamicTrading local branches, HEADs, upstream/divergence and concurrent/user changes; do not create a branch;
3. inspect the exact current local `PNC_SemanticDialogueSuggestions.lua`, predicate module, DialogueInput click route, response/branch offers, Conversation root/choice projection, translation catalogs and Semantic Lab worker/UI;
4. add/strengthen focused behavior-contract tests that freeze the current candidate/frame/localization/click behavior before refactoring;
5. run the real worker for representative initial-root, response-plan/branch, companion-capability and EN/TL cases;
6. update this ledger with exact revisions/tests and proceed directly into P1 if P0 passes.

### P0 acceptance

- no behavior-changing refactor bundled into the baseline test slice;
- real worker reproduces the current path;
- label and utterance translation keys remain separate and stable;
- stale/duplicate/capability authority cases are covered;
- current dynamic branch/root choices are covered;
- source ownership and safe local Git state are recorded.

## After P0

Continue autonomously P1 -> P7 according to `ROADMAP.md`. Do not wait for another user prompt merely because a phase passed.

## Handoff condition

Only after P1–P7 developer gates pass: **READY FOR USER LIVE TEST**.

Native PZ SP/MP remains user-owned and must be reported `UNTESTED` unless the user provides evidence.
