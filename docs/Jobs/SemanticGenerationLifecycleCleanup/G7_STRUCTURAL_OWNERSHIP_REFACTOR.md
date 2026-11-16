# G7 — Structural Ownership Refactor

**Status:** ACTIVE / NOT YET ACCEPTED — corrective phase after the G0–G6 lifecycle implementation audit.

## Goal

Finish the semantic-generation migration so the reconciler no longer needs a growing list of individual preserved/retired content files.

The steady-state repository must have four clear ownership classes:

```text
1. HAND-WRITTEN ENGINE / ADAPTER CODE
   ConvoEngine algorithms, services, adapters
   → normal source code
   → never generated

2. CANONICAL CODEBUILDER SEMANTIC SOURCE
   dialogue / behavior / beat / realization families
   → contains semantic structure + localized wording
   → edited through CodeBuilder authoring/migration APIs

3. GENERATED RUNTIME OUTPUT
   Lua modules, registries/manifests, generated conversation text
   → completely reproducible
   → closed-set reconciliation
   → safe to delete when absent from the desired plan

4. ORDINARY APPLICATION / TOOLING TRANSLATIONS
   debug UI, diagnostics, journals, non-dialogue application text
   → ordinary package assets
   → outside CodeBuilder generated-output ownership
```

The invalid steady-state class is:

```text
LEGACY HAND-AUTHORED RUNTIME DIALOGUE CONTENT
```

Dialogue/semantic wording that belongs to a ConvoEngine family must migrate into canonical CodeBuilder source and be generated from there.

## Normative naming and sharding rules

This refactor MUST preserve the accepted ConvoEngine contracts in:

- `psychopatzCore/Docs/semantic_dialogue_language_standard/CONVO_ENGINE.md`
- `psychopatzCore/Docs/semantic_dialogue_language_standard/NAMING_AND_LAYOUT.md`

Do not reinterpret those rules for cleanup convenience.

### Source modularity

- one source file = one coherent semantic exchange family/module;
- create directories for stable semantic ownership, not migration history or arbitrary file count;
- use lowercase `snake_case.json` source filenames describing semantic meaning;
- filesystem path improves discoverability but is not canonical identity;
- ordinary adopter owner derives from explicit family owner → manifest/shard owner → `defaultOwner`.

### Canonical IDs

Use concise semantic identities such as:

```text
social.argument.deescalate
task.fetch.completed
command.camp
behavior.social.warn
beat.social.argument
realization.social.acknowledge
```

Do not introduce implementation/history prefixes or suffixes such as:

```text
semantic.*
generated.*
legacy.*
codebuilder.*
runtime.*
*.v2
*.new
*.migrated
```

### Realizations and outcomes

- numeric `say` keys are stable wording-realization handles, not semantic IDs;
- gaps may remain after deletion; do not renumber surviving realization keys merely for contiguity;
- named reply keys represent semantic outcomes such as `known`, `unknown`, `accepted`, `rejected`, `pending`, `completed`;
- neutral/warm/terse/guarded/etc. stay style/context variants unless they genuinely represent different semantic meaning;
- phrase alternatives remain localized phrase arrays, not separate semantic families.

### Sharding

- do not create one file per phrase;
- do not create arbitrary `PartNN`, `Catalog02`, `Legacy`, `Compat`, `Old`, `V1`, or `Migrated` source trees;
- split broad sources by coherent semantic ownership only;
- generated chunking is allowed only when runtime budgets require it and must remain deterministic, source-lineage-aware, collision-safe and semantically identifiable;
- active hash-suffixed generated shards are valid when the generator's deterministic chunking requires them;
- never infer legacy status from a hash suffix;
- reuse/extend `catalog_naming.py`; do not create another naming algorithm.

### Runtime naming

Generated ConvoEngine Lua remains under:

```text
PsychopatzCore/ConvoEngine/
PNC/ConvoEngine/
DTCommon/ConvoEngine/
```

Do not restore redundant `Semantics/Generated/Conversation/PSDL` wrappers.

Generated status belongs in headers/manifests/fingerprints/lineage, not in directory taxonomy.

Steady-state generated text identity remains:

```text
template IDs:        convo.<family>.<role>...
Hoomans textDomain:  pnc.convo.<domain>...
text tree:           Conversation/Text/convo/...
```

Do not reintroduce `psdl.*`, `pnc.psdl.*`, or `Conversation/Text/psdl/`.

## Structural translation ownership

### CodeBuilder-owned dialogue text

All first-party dialogue/semantic wording that belongs to a ConvoEngine family must live with that family in canonical source.

Examples include:
- initiating speech;
- reply speech;
- flow reply wording;
- semantic response wording;
- generated affordance labels/player utterances where owned by the family;
- realization variants and localized phrase alternatives.

CodeBuilder emits these into a structurally generated-owned text surface, preferably the already accepted:

```text
Conversation/Text/convo/...
```

The generator owns that subtree as a closed set.

### Ordinary package translations

Application strings that are not ConvoEngine semantic/dialogue content remain ordinary package assets.

Examples may include:
- diagnostic/developer-tool UI;
- journal UI;
- provider-specific application interface text;
- world-event presentation text that is not an authored ConvoEngine exchange.

Their exact classification must be audited by purpose/callers. They must not remain in a CodeBuilder preserve allowlist merely because they currently share a `Conversation/` ancestor.

If necessary, move them to a stable non-generated package translation surface whose semantic/application ownership is clear.

### No mixed generated/authored catalog as steady state

Avoid a catalog where authored application keys and CodeBuilder-generated keys share one file.

The target is structural separation:

```text
ordinary authored package translation
        separate from
CodeBuilder-owned generated text subtree
```

If an unavoidable external compatibility seam temporarily requires a mixed catalog, generated-key ownership must be automatic and bounded. It must not become the preferred architecture.

## Recipe compaction

The permanent generation recipe describes surfaces and policies, not repository history.

Target characteristics:

- no list of every desired generated file;
- no growing list of individual authored translation files;
- no 40+ item historical retirement list;
- no list of active hash shards;
- no manual list of current generated UI keys.

The desired artifact set is compiled dynamically in memory from canonical source.

Long-lived tombstones are permitted only for compact structural anti-regression rules, for example a retired root pattern such as an old `Semantics/Generated/Conversation` tree. One-time historical filenames belong in audit/Git history and should be removed from the steady-state recipe after migration closure.

## Dynamic cleanup invariant

A future semantic family must require no recipe edit.

Acceptance scenario:

```text
create brand-new canonical family F
→ CodeBuilder generates arbitrary Lua/text outputs

remove canonical family F
→ do NOT edit generation_recipe.json
→ do NOT add a retirement
→ do NOT add a preserved path
→ do NOT add filenames/keys to a cleanup list

run normal canonical reconcile
→ every CodeBuilder-owned F artifact disappears automatically
→ ordinary authored code/assets remain untouched
→ clean second check
```

## Canonical CLI invariant

The command advertised by the recipe/help must execute successfully as written in the real multi-repository workspace.

Do not accept a test that merely checks whether the strings `reconcile.py`, `--check` and `--apply` appear.

The acceptance test must execute the advertised command from its documented working directory and verify the actual three-repository result.

Repository discovery may be automatic from workspace evidence or explicit in the canonical command, but the documented command must be truthful and self-contained.

## Migration rule

This is a root-cause migration, not a mass deletion.

For each currently preserved translation/catalog:

1. classify actual purpose and callers;
2. if it is ConvoEngine dialogue/semantic wording, migrate wording into the owning canonical family;
3. if it is ordinary application/tooling text, place it outside the generated-owned surface;
4. if obsolete, prove caller zero and remove it;
5. regenerate through CodeBuilder;
6. update exact callers/tests atomically;
7. prove old path/key caller zero;
8. remove temporary preserve/retirement recipe entries.

Do not create compatibility copies merely to keep old paths alive.

## Completion condition

G7 is complete only when the ordinary steady-state recipe is structurally small and future content removal does not require editing the recipe.

The clean repository state must be explainable from:

```text
canonical source
+ structural ownership rules
+ current generated plan
```

—not from a historical inventory of exceptions.
