# P11 — Remaining Modular Conversation Architecture

P11A and P11B0 are complete and no longer have separate active phase docs.
This document describes only the remaining P11 product work.

## P11B — one first-party wording authority

**Status:** IN PROGRESS.

Completed domains:

- Wellbeing;
- Needs;
- Health;
- Social Apology.

Continue by coherent domain shard, not individual string.

For each domain:

1. characterize production callers and placeholders once;
2. move first-party wording to canonical Dialogue Content;
3. migrate callers directly;
4. regenerate through CodeBuilder;
5. preserve EN fallback and all available locale placeholders;
6. run focused tests + full native Lua;
7. retire old keys only after caller-zero proof.

No broad compatibility-alias registry may hide unmigrated internal callers.

## P11C — source refinement

The manifest-backed modular compiler already exists.

P11C may refine shard boundaries only where real migrated content exposes a
problem:

- split oversized domains without changing canonical IDs;
- remove remaining pattern/wording mixtures;
- keep one source manifest/compiler;
- keep aggregate snapshots generated/read-only;
- keep GUI/agents independent of physical shard paths.

## P11D — Conversation UI Registry

Create one declarative navigation/presentation registry under the modular
Conversation source model.

It owns:

- landing choices;
- hubs;
- parent/child membership;
- order;
- labels/player utterance references;
- semantic/provider/predicate references.

It does not own gameplay eligibility/effects.

Primary acceptance: add/reorder/remove an existing semantic child under
**What's up?** without editing production Lua.

## P11E — taxonomy/naming cleanup

Remove compiler history from canonical identity.

Examples:

```text
semantic.generated.parameterized_task.fetch.failed
→ task.fetch.failed

semantic.question.wellbeing.fatigue
→ question.wellbeing.fatigue

semantic.social.apology.friendly
→ social.apology.friendly
```

`generated`, workflow kind, source shard, and module path belong in provenance
metadata.

Translation keys/file names are generated and should be shorter/domain-based.
Do not preserve obsolete internal names through a broad permanent alias table.

## P11F — one Conversation explorer

Replace the everyday Responses/Interactions/Dialogue Content split with one
Conversation hierarchy.

Selected-item details retain:

- Overview;
- Wording;
- Route;
- Conditions;
- Follow-ups;
- Sources.

Raw catalogs may remain only as narrow diagnostics.

## P11G — contextual Developer Tools

Developer Tools becomes the editor for the selected Conversation item.

Wording editor:

- all available locales;
- styles;
- add/duplicate/delete/reorder variants;
- preview;
- Review;
- explicit validated write/compile.

Conversation UI editor:

- labels/player utterances;
- parent/child membership/order;
- provider/predicate references;
- preview actual Conversation UI.

Dynamic gameplay authority stays locked.

## P11H — shared GUI/agent API

GUI and agents call the same canonical-ID service for:

- inspect;
- edit;
- add/remove/reorder;
- validate;
- preview;
- write;
- compile.

No generated-file direct editing.

## P11I — final acceptance

Required final state:

- one semantic meaning authority;
- one first-party wording authority;
- one Conversation UI/navigation authority;
- dynamic locale discovery with EN fallback;
- deterministic bounded generated artifacts;
- domain-meaning canonical names;
- consolidated Studio/editor workflow;
- typed/clicked/event parity;
- PBrainZ/compatibility parity;
- save safety;
- full regression/idempotence/Kahlua gates where tooling is available.

Only then return to `READY FOR USER LIVE TEST`.

## Non-goals

Do not create P12 or another dialogue engine.
Do not move gameplay authority into authoring JSON.
Do not hand-maintain generated artifacts.
