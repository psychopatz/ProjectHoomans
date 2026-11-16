# Roadmap — G9R Semantic Domain Decomposition & Generated Surface Normalization

**Parent status:** COMPLETE.
**Active phase:** G9R5 (Closed).
**Completion boundary:** G9R1–G9R5 accepted.

## G9R1 — global generated-topology audit + semantic path contract

Audit every generated semantic surface across PsychopatzCore, ProjectHoomans and DTCommon:
- `Behavior/`;
- `Behaviors/Director/`;
- `Beat/`;
- `Beats/Director/`;
- `Dialogue/`;
- `Realization/`;
- `Index/`;
- registries/manifests that compose them.

For every monolithic bucket and every `__????????` module, identify:
- source package/owner;
- kind;
- broad runtime domain;
- source lineage;
- exact naming collision partner;
- whether the collision is cross-owner, cross-surface, long-name, or true same-namespace collision.

Define one canonical semantic-path concept. Preferred semantics:

```text
domain      = broad runtime meaning, e.g. social
domainPath  = authored semantic hierarchy, e.g. social/conflict
```

Equivalent naming such as `semanticPath`/`subdomain` is acceptable, but do not overload runtime `domain` if consumers depend on its broad meaning.

Source hierarchy should derive this path automatically where possible:

```text
behavior/social/conflict/retaliate_verbally.json
→ domain = social
→ domainPath = social/conflict
```

**Gate:** compiler model exposes a deterministic owner + kind + semantic-path grouping key and diagnostics can explain every current generated collision.

## G9R2 — semantically decompose source families

Reorganize broad source buckets into coherent semantic subdomains so variants of the same type live together.

Do not invent arbitrary size partitions. Split by meaning first.

Candidate Core behavior groupings to audit, not blindly hard-code:
- acknowledgement/news/memory;
- conflict/challenge/warning/retaliation;
- repair/reconciliation/de-escalation/end-conversation;
- context/follow-up;
- world-event warning.

Candidate Hoomans scene groupings:
- horde;
- excursion;
- task/work;
- news/follow-up;
- post-combat/grounded scene events.

Beats, dialogue and realizations should use the same hierarchy when they genuinely contain multiple semantic subdomains.

Preserve:
- stable semantic IDs;
- package ownership;
- capability contracts;
- realization handles;
- source-lineage diagnostics;
- broad runtime domain semantics where required.

Adding another variant to a type should normally mean adding a source file beside related variants, not growing a giant catch-all file.

**Gate:** representative Core and Hoomans types have coherent source subdomains and compile to semantically equivalent canonical/portable plans.

## G9R3 — normalize generated surfaces by owner + semantic path

Remove hard-coded broad aggregation such as:

```text
all behaviors → social
all beats → social
```

Generated grouping should be based on:

```text
owner/package
+ kind
+ semantic domain path
```

Both the dedicated director data and portable runtime-plan surfaces must use the same semantic decomposition.

Example shape:

```text
PsychopatzCore/ConvoEngine/
  Behavior/Social/Acknowledgement.lua
  Behavior/Social/Conflict.lua
  Behavior/Social/Repair.lua

  Behaviors/Director/Social/Acknowledgement.lua
  Behaviors/Director/Social/Conflict.lua
  Behaviors/Director/Social/Repair.lua
```

ProjectHoomans-owned scene behavior must not be serialized into a Core-owned director payload merely because it uses Core's director runtime.

If a broad `Social.lua` compatibility/aggregator module is retained, it must be a small generated composition layer, not the monolithic semantic data payload.

Fix naming-registry scope so distinct owner/module namespaces do not create false collisions.

Do not create a second semantic authority. Both generated surfaces remain projections of the same canonical PSDL/Portable Dialogue Plan.

**Gate:** generated module ownership mirrors package ownership, semantic groups are readable, and no broad director payload crosses package boundaries.

## G9R4 — global readable naming + variant-growth stability

Apply readable naming acceptance to every owner, not only ProjectHoomans.

Required global result:

```text
PsychopatzCore avoidable __????????.lua = 0
ProjectHoomans avoidable __????????.lua = 0
DTCommon avoidable __????????.lua = 0
```

Hashes remain legal only for a proven true residual collision or hard backend/filesystem constraint.

Size/record budgets remain safety limits inside an already coherent semantic group. If one semantic subdomain still exceeds a budget, split that group with readable deterministic semantic chunk labels.

Stability tests must prove:
- adding an unrelated subdomain does not rename existing modules;
- adding a variant to `social/conflict` does not rename `social/repair` modules;
- source enumeration order does not change names;
- owner A cannot force a hash in owner B's namespace;
- retired old hash modules/references reconcile automatically.

Extend `locate`/audit output to report `domainPath` and generated surface(s).

**Gate:** all avoidable hashes are gone globally and ordinary variant growth changes only the relevant semantic group.

## G9R5 — committed-vector closure

After G9R1–G9R4:
1. run new domain/grouping/owner-isolation/naming-stability tests;
2. run G9 package tests;
3. run G8R7 portability tests and G8 production tests;
4. run lifecycle tests;
5. canonical reconcile check clean before apply;
6. run `audit-s6m8 --check-determinism`;
7. reconstruct the final participant commit vector;
8. delete ledger-owned generated artifacts and rebuild;
9. verify second build no-op and final check clean;
10. verify old `Social__*`, `CoreKnowledgeFacts__*`, and any other retired avoidable hash references/artifacts are absent;
11. reconcile active docs to COMPLETE;
12. commit participant repos first and ProjectHoomans/job docs last.

**Gate:** source and generated layouts are semantically decomposed, package-isolated, readable and deterministic across the final committed vector.

## Non-goals

- do not remove the 192 KiB / 32-record safety budgets merely to avoid shards;
- do not rename stable semantic IDs for filesystem aesthetics;
- do not move game mechanics into PSDL;
- do not create file-per-phrase or arbitrary PartNN decomposition;
- do not hand-rename generated Lua;
- do not reopen backend portability architecture unless a regression is found.
