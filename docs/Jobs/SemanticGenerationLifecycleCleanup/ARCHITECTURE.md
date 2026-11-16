# Architecture — Semantic Generation Lifecycle Cleanup

## 1. Authority model

Canonical semantic authoring remains upstream of generated runtime output.

```text
ConvoEngine canonical source families / manifests / text sources
                    ↓
              CodeBuilder
                    ↓
          desired artifact plan
                    ↓
          lifecycle reconciler
                    ↓
       generated runtime artifacts
```

Generated Lua/JSON is downstream output and is never the canonical place to repair semantic content.

## 2. Generation recipe

Add one compact machine-readable recipe owned by PsychopatzCore, conceptually:

```text
psychopatzCore/
  tools/semantic_harness/codebuilder/
    generation_recipe.json
```

The exact filename may change only if a better existing CodeBuilder convention is discovered. There must still be one obvious recipe entrypoint.

The recipe should describe **surfaces**, not enumerate every generated file.

Conceptual schema:

```json
{
  "schema": "psychopatz.semantic-generation-recipe.v1",
  "surfaces": [
    {
      "id": "conversation_lua",
      "generator": "conversation",
      "owners": ["PsychopatzCore", "ProjectHoomans", "DTCommon"],
      "policy": "owned_fileset"
    },
    {
      "id": "conversation_translations",
      "generator": "conversation",
      "policy": "owned_fileset"
    },
    {
      "id": "conversation_ui",
      "generator": "conversation",
      "policy": "mixed_key_catalog"
    },
    {
      "id": "conversation_text",
      "generator": "conversation_text",
      "policy": "owned_fileset"
    }
  ],
  "retired": []
}
```

The recipe is intentionally small. Current desired output paths are derived from compilers/render plans.

## 3. Artifact policies

### `owned_fileset`

The complete file is CodeBuilder-owned.

After successful reconciliation:
- every desired file exists with canonical generated content;
- every previously owned file not in the desired set is absent;
- unrelated authored files outside the declared surface remain untouched.

### `mixed_key_catalog` — transition/compatibility only

A file contains both authored and generated keys. The reconciler must maintain explicit generated-key ownership so authored keys survive and formerly generated keys can be pruned safely.

This is **not** the preferred steady-state architecture. G7 moves first-party ConvoEngine wording into canonical family source and structurally generated-owned text surfaces, while ordinary application/tooling translations remain outside CodeBuilder ownership. New first-party semantic content must not create new mixed catalogs merely for convenience.

### `must_not_exist`

Used for retired legacy paths/roots.

A retired entry is an anti-regression tombstone. If a retired generated path reappears, `--check` fails.

### `preserve` — migration-only escape hatch

A preserve entry protects a known neighboring asset while ownership is being migrated. It must not become a growing permanent allowlist. G7 removes per-file preserve inventory by giving generated text a structurally owned surface and leaving ordinary authored assets outside that surface.

## 4. Desired artifact ledger

Each generation run should build an in-memory ledger before mutation.

Minimum row shape:

```text
owner
surface
path
artifact kind
source lineage
cleanup policy
content fingerprint
generated-key set when applicable
```

The ledger is the machine authority for cleanup decisions.

A persisted compact receipt is allowed only when ownership cannot be structurally rediscovered safely. It must be automatic, machine-owned, bounded, and never become a second authoring source or a manually maintained file list. Prefer structural ownership over receipts whenever possible.

## 5. Safe deletion proof

A file may be deleted automatically only when the reconciler can prove CodeBuilder ownership by one of these mechanisms:

1. the path is in a declared fully owned generated surface and carries the accepted generated marker/receipt;
2. the path is present in a previous trusted generation receipt but absent from the new desired ledger;
3. the path is an exact declared retirement/tombstone whose ownership is proven by audit;
4. for mixed catalogs, the individual key is present in the previous generated-key set.

Unknown files are not deleted. They are reported as ambiguous and require one-time classification.

No deletion by:
- timestamp;
- filename hash pattern;
- generic words such as `legacy`, `old`, or `generated`;
- directory age;
- Git-untracked status alone.

## 6. Transaction ordering

The lifecycle must be fail-closed.

```text
discover workspace
    ↓
compile complete desired model
    ↓
validate owners/routes/context health
    ↓
build desired artifact ledger
    ↓
compute proposed prune/write diff
    ↓
CHECK MODE: stop here and report
    ↓
APPLY MODE:
  prune proven stale artifacts/keys
  write canonical current outputs
    ↓
post-write closure verification
```

Compilation or validation failure must leave runtime outputs untouched.

## 7. Canonical agent UX

Provide one programmatic entrypoint with equivalent behavior to:

```bash
python tools/semantic_harness/codebuilder/reconcile.py --recipe tools/semantic_harness/codebuilder/generation_recipe.json --check
python tools/semantic_harness/codebuilder/reconcile.py --recipe tools/semantic_harness/codebuilder/generation_recipe.json --apply
```

Exact module/CLI naming may follow current project conventions, but agents must have one obvious check/apply workflow.

Expected check report:

```text
desired
missing
drifted
stale
retired_present
ambiguous
preserved
```

A clean result requires:

```text
missing = 0
drifted = 0
stale = 0
retired_present = 0
ambiguous = 0
```

## 8. Legacy retirements

The first implementation includes a one-time inventory of historical generated outputs across ProjectHoomans, PsychopatzCore and DTCommon.

Confirmed obsolete paths should be encoded as:
- retired roots when the whole root is unambiguously obsolete and generated-owned; or
- exact retired paths with fingerprint/header evidence.

Retirement entries should remain only when they are compact structural anti-regression rules. One-time historical filenames belong in audit/Git history and should leave the steady-state recipe after migration closure.

The implementation must not manually delete first and document later. The reconciler must be capable of performing the accepted cleanup itself.

## 9. Agent-readability invariant

Future agents should normally need only:

```text
root AGENTS.md
generation recipe
reconciliation report
canonical semantic source being changed
relevant tests
```

They should not need to enumerate the generated tree to determine whether it is safe to clean.

## 10. Repository responsibility

PsychopatzCore owns:
- recipe schema;
- reconciler;
- generic CodeBuilder lifecycle;
- Core-owned generated outputs.

ProjectHoomans owns:
- Hoomans semantic source/adopter content;
- this job documentation;
- Hoomans-owned generated outputs only as downstream artifacts.

DynamicTrading/DTCommon owns:
- DTCommon semantic source/adopter content;
- DTCommon generated outputs only as downstream artifacts.

The reconciler routes by explicit package ownership. It must not guess unknown owners as ProjectHoomans.

## 11. G7 structural ownership steady state

G0–G6 established the reconciler. G7 removes migration-era exception inventory so ordinary maintenance is driven by structure rather than remembered filenames.

The four steady-state classes are:

```text
HAND-WRITTEN ENGINE/ADAPTER CODE
CANONICAL CODEBUILDER SEMANTIC SOURCE
GENERATED RUNTIME OUTPUT
ORDINARY APPLICATION/TOOLING TRANSLATIONS
```

There is no steady-state class for hand-authored runtime dialogue wording. If text belongs to a ConvoEngine semantic family, its canonical EN/TL wording belongs with that family and CodeBuilder generates the runtime text.

### Structural generated text

The preferred generated text surface is the already accepted ConvoEngine text tree:

```text
Conversation/Text/convo/...
```

CodeBuilder owns that subtree as a closed set. Ordinary debug/tooling/journal/application translations must not be kept inside this generated ownership merely to avoid migration work.

### No historical exception inventory

The permanent recipe must not enumerate:
- every active generated file;
- every authored neighboring translation file;
- active hash-suffixed shards;
- current generated UI keys;
- large one-time lists of historical filenames.

The desired artifact ledger is derived dynamically from canonical source. Compact structural tombstones may remain for old roots whose reappearance is itself a regression.

### Naming/sharding preservation

G7 does not reopen accepted ConvoEngine modularity. `psychopatzCore/Docs/semantic_dialogue_language_standard/CONVO_ENGINE.md` and `NAMING_AND_LAYOUT.md` remain normative. In particular:
- one coherent semantic family/module per source file;
- lowercase semantic `snake_case.json` filenames;
- concise semantic canonical IDs;
- stable realization keys are wording handles, not semantic IDs;
- named reply outcomes retain semantic meaning;
- no phrase-per-file or arbitrary `PartNN` source sharding;
- no `Legacy`, `Compat`, `Old`, `V1`, `Migrated` migration trees;
- deterministic generated chunking may use collision-safe hash suffixes when runtime budgets require it;
- never classify a desired hash-suffixed shard as legacy by name;
- reuse `catalog_naming.py`; never create another naming algorithm;
- generated ConvoEngine runtime remains under `<Owner>/ConvoEngine/...`;
- steady-state text naming remains `convo.*`, `pnc.convo.*`, and `Conversation/Text/convo/...`.

See `G7_STRUCTURAL_OWNERSHIP_REFACTOR.md` for the active migration plan.
