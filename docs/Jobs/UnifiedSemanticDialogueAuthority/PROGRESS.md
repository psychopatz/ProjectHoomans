# Progress — Unified Semantic Dialogue Authority

**Status:** PAUSED / READY TO RESUME.
**Current branch:** `main`.
**Last accepted published baseline before this cleanup:** `c78a97fc`.

## Accepted foundation

Accepted and preserved:

- P0–P10 semantic-authority and zero-legacy foundation;
- P11A steady-state cleanup;
- P11B0 modular Conversation compiler/source foundation;
- P11B Wellbeing wording domain;
- P11B Needs wording domain;
- P11B Health wording domain;
- P11B Social Apology wording domain.

Detailed per-domain characterization files have been removed from the active
job docs. Git history preserves that evidence.

## Compiler/translation hygiene completed in the current worktree

The current cleanup makes CodeBuilder, not generated output, the owner of
formatting and locale behavior:

- canonical Conversation shards remain the authoring source;
- generated JSON uses deterministic pretty formatting;
- generated `Conversation.json` is rebuilt from actual locale directories and
  Conversation files instead of incrementally mutated EN/TL tables;
- EN is the required fallback locale;
- additional locales are discovered from source translation maps/directories;
- old `en`/`tl` source fields are accepted only through one centralized
  backward-compatibility reader;
- automatic-flow metadata no longer carries a duplicate EN/TL translation-path
  table;
- a synthetic third locale test proves a new locale is generated/registered
  without adding a compiler whitelist entry.

## Validation for this cleanup

Verified:

- focused compiler/authoring Python: 7/7 PASS;
- automatic-flow / locale-focused Python: 3/3 PASS;
- focused Lua translation/automatic-flow: PASS;
- full native Lua: 897/897 PASS;
- two-pass generated artifact hash: identical;
- CodeBuilder Python modules: py_compile PASS.

The local environment did not expose a `pz-verify` executable on PATH, so no
new Kahlua verifier claim is recorded here.

## Current output state

Generated Conversation domain JSON is readable multi-line JSON. Legacy
CodeBuilder-owned compatibility outputs such as
`CommonInteractions.json`, `GroundedPersonalDialogue.json`, and
`Generated.json` also regenerate in readable deterministic JSON.

`GeneratedTaskCommand*.json`, `Responses.json`, and `Realizations.json`
remain separate legacy/current runtime surfaces pending their documented P11B/
P11E migration. Do not hand-clean them; change their owning generator/authority
when their migration phase is reached.

## Next chunk when resumed

Resume **P11B by coherent domain**, not by individual string.

Recommended next domain: **Task Fetch**.

For each domain:

1. characterize callers/placeholders once;
2. migrate the domain through canonical Conversation shards;
3. regenerate through CodeBuilder;
4. run focused tests plus full native Lua;
5. retire superseded keys only after caller search reaches zero;
6. keep generated files downstream-only.

After P11B completes, continue P11C–P11I in `ROADMAP.md`.

## Stop / safety rules

Do not push unless explicitly authorized.
Do not launch native Project Zomboid or publish Workshop content.
Do not create new mandatory phases.
Do not restore or merge parked/recovery branches wholesale.
Do not treat generated JSON/Lua as an authoring surface.
