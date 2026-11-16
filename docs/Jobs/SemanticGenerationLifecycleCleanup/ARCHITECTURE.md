# Architecture — Portable PSDL / ConvoEngine

## Authority pipeline

```text
compact PSDL package
→ canonical Semantic Dialogue IR
→ Portable Dialogue Plan
→ descriptor-selected backend
→ generated runtime
→ typed game capability adapter
```

There is one semantic-plan authority and one backend-dispatch authority.

## Package ownership

```text
PsychopatzCore
  compiler
  standard runtime
  reusable semantic stdlib

ProjectHoomans
  Hoomans/domain PSDL programs

DTCommon
  Dynamic Trading/domain PSDL programs
```

Adopters import shared Core packages. Core does not hard-code adopter source roots.

## Semantic decomposition

Organize by meaning before safety sharding:

```text
package
→ kind
→ domain
→ domainPath
→ variants
→ generated module
```

Broad `domain` may preserve runtime semantics. `domainPath` is derived from source/package hierarchy and drives generated grouping and navigation.

Example:

```text
behavior/social/conflict/retaliate_verbally.json
→ domain = social
→ domainPath = social/conflict
```

Adding a variant should normally affect only its semantic group.

## Generated surfaces

Generated data mirrors source-package ownership.

Core-owned semantic source generates Core-owned modules. Hoomans-owned source generates PNC modules. Shared runtime/director code may consume imported packages without merging adopter data into Core payloads.

Distinct generated surfaces such as portable runtime-plan modules and director/catalog modules remain projections of the same canonical semantic model. Neither is an authoring authority.

Broad aggregator/index modules are allowed only as composition/discovery surfaces, not monolithic semantic payloads.

## Naming and safety sharding

Generated naming is deterministic and scoped by final owner/backend namespace.

Readable semantic hierarchy is preferred. Compact hashes are only a true residual collision/backend-limit fallback.

Safety ceilings remain downstream constraints:

```text
max generated shard bytes = 192 KiB
max records per shard = 32
```

They do not define semantic organization.

`catalog_naming.py` remains the naming authority. Generated files are never hand-renamed.

## Portability boundary

```text
portable declaration → PSDL
portable reusable algorithm → standard runtime
game/engine implementation → typed capability adapter
backend rendering → descriptor-selected backend
```

Fuzzy matching, predicates and directors are reusable runtime algorithms. Game mechanics such as PZ camp geometry/pathfinding/server mutation remain adopter capability implementations.

## Preserved invariants

Keep stable semantic IDs, realization handles, named outcomes, explicit authored/canonical lineage, deterministic output, closed-set reconciliation, no arbitrary `PartNN`/phrase-per-file/migration-history authoring trees, and no revival of legacy `psdl.*` runtime identities.
