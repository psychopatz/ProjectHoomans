# Storage Topology — Conversation CodeBuilder

Read this file when implementing C5 or changing Conversation source discovery, generated sharding, indexes, or context-health policy. It is intentionally not part of the default job read order.

## Objective

Keep canonical source, generated runtime artifacts and agent/tool discovery surfaces modular enough that scale does not force humans or LLM agents to load unrelated conversation catalogs.

Core rule:

> Source is atomic. Generated output is semantically sharded. Indexes point instead of aggregate. Paths explain ownership. Numeric overflow shards are forbidden. Runtime combinations remain ephemeral.

## Canonical source topology

Prefer one bounded semantic unit per file:

```text
conversation/
├─ beats/<domain>/<subdomain>/<semantic_name>.json
├─ behaviors/<domain>/<subdomain>/<semantic_name>.json
├─ affordances/<domain>/<subdomain>/<semantic_name>.json
├─ realization/
│  ├─ constructions/<locale>/<domain>/<semantic_name>.json
│  └─ lexicon/
│     ├─ semantic/<domain>.json
│     └─ locale/<locale>/<domain>.json
├─ content/authored/<domain>/<subdomain>/<semantic_name>.json
├─ flows/<domain>/<semantic_name>.json
├─ patterns/<domain>/<subdomain>/<semantic_name>.json
└─ ui/authored/<domain>/<semantic_name>.json
```

Paths should reveal kind/domain/purpose before a file is opened.

Prefer IDs that mirror ownership, for example:

- `behavior.social.hostility.retaliate_verbally`;
- `affordance.social.repair.apologize`;
- `construction.en.social.mirror_retort`.

Avoid catch-all source files once a domain has meaningful subdomains.

## Generated topology

Generated output should use semantic family shards, for example:

```text
Generated/Conversation/
├─ Behaviors/Social/Hostility.lua
├─ Behaviors/Social/Repair.lua
├─ Beats/Social/Conflict.lua
├─ Affordances/Social/Hostility.lua
├─ Realization/Constructions/EN/SocialHostility.lua
├─ Content/Authored/Social/Hostility.lua
└─ Index/
   ├─ Behaviors.lua
   ├─ Beats.lua
   ├─ Affordances.lua
   └─ Registry.lua
```

Indexes contain routing/identity metadata and bounded relationships; they do not duplicate every full definition.

Forbidden scaling pattern:

- `SocialPart02.lua`;
- `SocialPart03.lua`;
- `CommandPart02.lua`;
- `QuestionPart02.lua`.

If a shard exceeds budget, split it by semantic subdomain rather than numeric suffix.

Opaque generated names that do not explain semantic ownership are also forbidden for new Conversation output.

## Current migration targets

Current generated output still includes context-hostile names such as:

- `Content/SocialPart02.lua`, `SocialPart03.lua`, `SocialPart04.lua`;
- `Content/CommandPart02.lua`;
- `Patterns/QuestionPart02.lua`;
- `Patterns/Massive.lua`;
- `Patterns/Sgd.lua`.

C5 must migrate these to semantic ownership paths without changing runtime semantics.

## Manifest and discovery

The root Conversation manifest should contain schema/compiler configuration, approved source roots, domains/locales and generation policy.

It should not become a catalog containing every semantic record.

Use deterministic recursive discovery inside approved source roots.

## Context-health budgets

CodeBuilder must support configurable limits and report violations.

Initial targets may be tuned from measured repository data, but a useful starting policy is:

- preferred canonical record < 8 KB;
- hard canonical record ceiling ~16 KB;
- preferred generated semantic shard < 24 KB;
- hard generated shard ceiling ~48 KB;
- preferred definitions/shard <= 16;
- hard definitions/shard <= 32;
- zero numeric overflow shard names;
- zero opaque ownership names in new generated Conversation output.

The budget numbers are policy inputs. The guardrail is mandatory.

Context-health output should include:

- largest canonical files;
- largest generated shards;
- definitions per shard;
- oversized indexes;
- numeric/opaque naming violations;
- orphan/collision/reference failures.

## Agent/tool discovery indexes

Generate lightweight indexes such as:

```text
behavior.social.hostility.retaliate_verbally
  source: behaviors/social/hostility/retaliate_verbally.json
  generated: Behaviors/Social/Hostility.lua
  related:
    - beat.social.conflict.argument_escalation
```

The purpose is cheap routing. Do not duplicate complete definitions.

Prefer separate bounded indexes by kind when a single discovery index becomes large.

## Dependency-aware compilation

CodeBuilder should expose affected-closure discovery for a changed semantic record so development/harness workflows can identify the relevant source, generated shard and dependent indexes without reading unrelated catalogs.

Targeted compilation may improve iteration speed, but a full deterministic build remains the final correctness gate.

## Runtime and save storage

Never pre-expand or persist combinatorial dialogue possibilities.

Keep these ephemeral:

- generated button candidates;
- UtterancePlans;
- realized sentences;
- NLU/discourse traces;
- runtime strategy × lexeme × style × relationship combinations;
- full transcripts.

Persist only bounded semantic state legitimately owned by gameplay/social systems, such as active topic/beat, compact recent semantic acts, grounded facts and coalesced relationship/conduct memory.

## C5 acceptance

C5 passes only when:

- source discovery is deterministic;
- new records do not require editing giant catalogs;
- generated output contains no numeric overflow shards;
- current opaque/numeric migration targets are removed;
- context-health budgets pass;
- discovery indexes remain lightweight;
- affected-closure metadata is available where feasible;
- two consecutive full builds are byte-identical;
- existing semantic/runtime behavior is unchanged;
- runtime combinations remain ephemeral.
