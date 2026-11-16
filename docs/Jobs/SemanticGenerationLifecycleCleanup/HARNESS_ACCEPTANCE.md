# Harness Acceptance — Semantic Generation Lifecycle Cleanup

## Principle

A cleanup system is not accepted because generation succeeds. It is accepted only when creation, deletion, migration, preservation and repeatability all behave correctly.

## Required fixture matrix

### Fully owned generated file

```text
source A + source B
→ generate
→ A output exists
→ B output exists

remove source B
→ check reports B stale
→ apply
→ B output absent
→ A output unchanged/canonical
```

### Source rename

```text
source old-name
→ output old-path

rename canonical source
→ check reports old-path stale + new-path missing
→ apply
→ old-path absent
→ new-path present
```

### Owner migration

At minimum:
- ProjectHoomans → PsychopatzCore;
- ProjectHoomans/Core → DTCommon where supported.

Old owner output must disappear and new owner output must appear.

### Mixed UI catalog

Fixture must contain:
- authored key;
- generated key A;
- generated key B.

Then remove generated source B.

After apply:
- authored key remains exactly;
- generated A remains canonical;
- generated B is absent.

### Conversation/Text

Prove the existing closed-set behavior still works through the unified lifecycle path.

### Retired path

Create a fixture matching a declared retirement.

Check mode must report it as `retired_present`.
Apply must remove it only when ownership evidence is valid.
A second check must be clean.

### Unknown neighbor

Create an unknown hand-authored file beside generated content.

Apply must preserve it and either:
- classify it as preserved by declared boundary; or
- report it as ambiguous.

It must never be silently deleted.

### Active hash shard

Use an actually desired hash-suffixed generated module.

Check/apply must preserve it because it is in the desired ledger.

## Transaction safety

Cause generation-plan validation to fail before mutation.

Assert that existing runtime outputs are unchanged.

No partial cleanup is acceptable after a failed compile/validation stage.

## Determinism

Run canonical apply twice from the same source.

The second pass must:
- write no semantic changes;
- prune nothing;
- report no stale/missing/drift/retired/ambiguous owned output;
- leave Git diff unchanged.

## Real repository closure

After fixture acceptance, run against the real participant repositories with isolated evidence capture first.

Final clean report for every enabled owner:

```text
missing = 0
drifted = 0
stale = 0
retired_present = 0
ambiguous = 0
```

Preserved authored assets may be nonzero.

## Regression suites

Run:
- generation ownership tests;
- conversation compiler/build tests;
- translation/text catalog tests;
- new lifecycle reconciliation tests;
- affected provider/adopter tests;
- deterministic full Conversation generation;
- syntax/format checks required by participant repositories.

The implementing agent should discover current exact test commands rather than relying on stale command strings in this planning document.

## Evidence labels

Use:
- CODE_VERIFIED
- TEST_VERIFIED
- GENERATED_OUTPUT_VERIFIED
- STATIC_ONLY
- USER_ACCEPTED when applicable

Do not claim runtime/native acceptance when no native game test was run.

## G7 structural ownership acceptance

G7 adds acceptance beyond the original G0–G6 matrix.

### Future-family cleanup without recipe edits

Create a brand-new canonical semantic family through the normal CodeBuilder authoring path. Let it generate novel Lua and localized text outputs. Then remove that family from canonical source and run the ordinary canonical reconciliation workflow.

During removal:
- do not edit `generation_recipe.json`;
- do not add a retirement entry;
- do not add a preserve path;
- do not add generated filenames/keys to a list.

Acceptance:
- every generated artifact owned by that family disappears automatically;
- ordinary engine/adaptor code remains untouched;
- ordinary application/tooling translations remain untouched;
- a second check is clean and a second apply is a no-op.

### Preserve-list elimination

The steady-state recipe must not require a list of every authored neighboring translation file or hand-written ConvoEngine Lua file. Test that new ordinary authored assets outside the generated-owned surfaces do not require recipe changes merely to coexist.

### Translation authority closure

For each migrated semantic/dialogue catalog:
- canonical localized wording exists in the owning ConvoEngine family;
- generated runtime text is reproducible from that source;
- old hand-authored runtime wording has caller zero before removal;
- ordinary non-dialogue application/tooling text remains package-authored and outside generated ownership.

`Flows.json` / `companion_flows/follow.json` must be included as a concrete regression proving duplicate runtime wording is eliminated at the source rather than preserved as an exception.

### No mixed catalog as preferred steady state

First-party ConvoEngine-generated text should live in a structurally generated-owned subtree such as `Conversation/Text/convo/...`. Mixed generated/authored catalogs may remain only where an explicit compatibility seam requires them; their generated-key ownership must be automatic and tested.

### Canonical CLI execution

Execute the exact command advertised by the recipe/help from its documented working directory. It must successfully resolve the real ProjectHoomans + PsychopatzCore + DTCommon workspace and return the expected clean check/apply result.

A test that only searches command text for `reconcile.py`, `--check`, or `--apply` does not satisfy this gate.

### Naming and sharding non-regression

Run the accepted ConvoEngine naming/layout/modularity audits and prove:
- one coherent semantic family per canonical source file;
- lowercase semantic `snake_case.json` source names;
- concise semantic canonical IDs;
- numeric realization keys remain wording handles, not semantic IDs;
- named reply outcomes remain semantic outcomes;
- no new `Legacy`, `Compat`, `Old`, `V1`, `Migrated`, `PartNN`, `Catalog02`, or phrase-per-file sharding;
- generated chunking remains deterministic, collision-safe and source-lineage-aware;
- desired hash-suffixed generated shards survive;
- `catalog_naming.py` remains the naming authority;
- no manual generated-file moves;
- no `psdl.*`, `pnc.psdl.*`, or `Conversation/Text/psdl/` steady-state output.

### G7 closure

The parent goal may return to COMPLETE only when the repository state is explainable from structural ownership + current canonical source + current desired plan, not from a growing historical exception inventory.
