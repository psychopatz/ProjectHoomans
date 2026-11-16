# Architecture — Semantic Generation Lifecycle Cleanup

## 1. Authority model

Canonical semantic authoring remains upstream of generated runtime output.

```text
PSDL / source shards / manifests / text sources
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

### `mixed_key_catalog`

The file contains both authored and generated keys.

The reconciler must maintain explicit generated-key ownership.

Result:

```text
existing authored keys
+ current generated keys
- formerly generated keys no longer desired
```

An authored key must never be deleted merely because it is absent from current generation.

### `must_not_exist`

Used for retired legacy paths/roots.

A retired entry is an anti-regression tombstone. If a retired generated path reappears, `--check` fails.

### `preserve`

Explicitly declares neighboring content that the lifecycle reconciler must never mutate.

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

A persisted compact receipt is allowed if needed to safely distinguish prior generated keys or pre-existing generated files, but it must not become a second authoring source.

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

Retirement entries should remain as compact tombstones when useful to prevent accidental reintroduction.

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
