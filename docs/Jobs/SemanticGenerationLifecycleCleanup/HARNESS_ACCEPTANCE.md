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
