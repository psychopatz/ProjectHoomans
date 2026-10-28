# Current Audit — Unified Semantic Dialogue Authority

**Audit point:** current local worktree on top of `c78a97fc`.

## Verified current architecture

The modular Conversation foundation is real and active:

- canonical source lives under
  `tools/semantic_harness/codebuilder/sources/conversation/`;
- one manifest inventories content/pattern/flow/UI shards;
- CodeBuilder merges and validates the whole model;
- runtime Conversation output is generated into bounded shards;
- the generated registry is a small hub rather than a content monolith;
- old aggregate source files are generated/read-only compatibility views.

P11B has already migrated the Wellbeing, Needs, Health, and Social Apology
wording domains.

## Translation/compiler audit

The previous compiler still treated Tagalog as a hard-coded second language in
multiple modules. That was inconsistent with the runtime translation catalog,
which already loads languages from `media/translation/manifests/Conversation.json`.

The current worktree corrects that boundary:

- EN is the required fallback locale;
- other locale codes are discovered from generic `translations` maps and
  actual translation directories;
- historical `en`/`tl` fields are normalized only by one compatibility
  adapter;
- the Conversation translation manifest is generated from actual locale files;
- automatic-flow semantic metadata no longer duplicates EN/TL path tables;
- generated Conversation JSON is pretty, deterministic, newline-terminated;
- a synthetic `XX` locale proves a third language works without changing a
  whitelist.

## Output-format audit

The one-line output visible in files such as
`GroundedPersonalDialogue.json` was produced by compact JSON renderers.

CodeBuilder renderers now emit readable deterministic JSON. Regeneration fixed
CodeBuilder-owned modular bundles and compatibility outputs including:

- Conversation domain bundles;
- `CommonInteractions.json`;
- `GroundedPersonalDialogue.json`;
- semantic `Generated.json`;
- generated `Conversation.json` manifest.

`GeneratedTaskCommand*.json`, `Responses.json`, and `Realizations.json`
remain owned by older runtime/migration surfaces. They should not be manually
reformatted; their owning generator/authority should change when P11B/P11E
reaches them.

## Validation

Current cleanup evidence:

- compiler/authoring focused Python: 7/7 PASS;
- locale/automatic-flow focused Python: 3/3 PASS;
- synthetic third-locale acceptance: PASS;
- full native Lua: 897/897 PASS;
- two consecutive generated-artifact trees: identical SHA-256;
- CodeBuilder py_compile: PASS.

No current `pz-verify` executable was available on PATH, so no new Kahlua
verifier claim is made.

## Remaining product gap

The system is not yet finished. Remaining mandatory work is P11B–P11I in
`ROADMAP.md`, beginning with the next coherent wording domain (recommended:
Task Fetch).

The most visible later cleanup is P11E: remove implementation-history taxonomy
such as `semantic.generated.parameterized_task.*`, shorten canonical IDs and
translation keys, and keep generator provenance as metadata.

## Scope warning

Do not reopen completed migration phases or recreate historical compatibility
systems. Git history is the archive. New work must improve the current modular
compiler/source architecture rather than clean generated files by hand.
