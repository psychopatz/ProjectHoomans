# Architecture — Unified NPC Population and Expansion Boundary

## Governing rule

**Core owns canonical world population truth, Project Hoomans owns NPC
materialization, and expansions own domain intent and behavior.**

An expansion is allowed to be standalone in its domain code, but it is not
allowed to become a second population authority.

## Target layering

```text
Dynamic Trading / future Gang / other expansion
  - source registration
  - domain profiles and member specs
  - commercial, gang, or other behavior
  - source-specific cadence/caps as policy
                 |
                 v
PsychopatzCore
  - source registry and activation
  - canonical group/actor generation plan
  - stable IDs and provenance
  - persistence, collision/idempotency, generic orchestration
                 |
                 v
Project Hoomans
  - PNC records and faction policy
  - abstract/live presence projection
  - body creation and nearby lifecycle
  - NPC monitor, map, and debug adapters
```

Core must remain below both adopters in the dependency graph. Hoomans may
depend on Core. Dynamic Trading may depend on Core and optionally Hoomans for
physical representation. A future Gang mod follows the same shape.

## Canonical lifecycle

```text
source registered and enabled
        |
        v
Core validates source request and builds group plan
        |
        v
Core commits group/faction/actor records once
        |
        +--> Hoomans absent: abstract/domain projection only, if supported
        |
        +--> Hoomans present: adopt/materialize PNC records
                              |
                              +--> abstract (no body nearby)
                              +--> live (body exists)
        |
        v
map / monitor / provider handoff reads canonical actor + normalized state
```

Representation changes are projections of one actor. They are not actor
creation events.

## Stable contracts

The exact Lua names are implementation work, but the contracts are fixed.

### Core source contract

Each source registration contains, at minimum:

- stable `sourceID` and expansion provenance;
- source activation/availability;
- generation kind and domain profile identifier;
- source-specific policy values such as cap, interval, and cooldown;
- a request builder or serializable request payload;
- compatibility/version information for save migration.

Core returns a canonical result containing:

- `groupID` and `factionID`;
- stable `actorIDs` and member metadata;
- source/provenance metadata;
- canonical world position/location;
- commit/reconciliation status.

Core owns validation, ID allocation, collision handling, idempotency, and
durable commit. An expansion may propose IDs only as deterministic hints; it
cannot make them authoritative.

### Hoomans materializer contract

Hoomans accepts a committed Core group and either adopts or materializes each
member through one idempotent boundary. It owns:

- PNC identity/record creation and update;
- faction/role/actor policy resolution;
- body creation, nearby lifecycle, and physical state;
- abstract/live presence projection;
- monitor/map/debug integration.

The materializer must never create a new canonical actor as a side effect of
failing to find a Core actor. It must return a bounded failure or request the
Core adoption/reconciliation seam.

### Expansion contract

An expansion supplies domain data and behavior:

- source registration;
- faction/profile/member specifications;
- source-specific lifecycle and policy;
- domain behavior and UI labels;
- optional abstract representation when Hoomans is absent.

It must not write PNC records, create bodies, mutate Core actor IDs directly,
or maintain a parallel group roster.

## Presence state invariant

The only valid materialization states are:

```text
abstract  — canonical actor exists; no physical body is leased
live      — canonical actor exists; a provider owns a physical body lease
```

`UNKNOWN`, `missing`, provider names, and nil are not valid user-facing
presence states. An incomplete chain is diagnostic data, not a third mode.

Required behavior:

1. A map marker or hover target must resolve to a canonical actor before it is
   shown.
2. A canonical actor without a materializer is allowed to remain abstract.
3. A Hoomans record without a Core actor must be adopted/reconciled or hidden;
   it must not silently invent an actor.
4. A body lease must reference the same actor ID used by Core, PNC, monitor,
   and map hover.
5. A provider handoff changes the lease/projection only; it never duplicates
   the canonical actor or PNC record.

## Current seams and planned changes

| Current evidence | Interpretation | Planned boundary |
| --- | --- | --- |
| Core `BuildGroupPlan` and `CommitGroupPlan` | Canonical generation foundation exists | Add generic source registration/orchestration around it |
| Hoomans `MaterializeCoreGroup` | Physical integration already has a seam | Stabilize it as the only expansion-to-body boundary |
| Hoomans fixed faction/mobile archetype gates | New expansion types would require edits or bypasses | Register faction/role/materialization policy |
| DT trader generation façade and `TraderWorld` cadence | Trader domain still owns generic-looking generation flow | Register DT source with Core; retain trader policy locally |
| DTAbstract/DTHoomans providers | Useful representation split | Keep both as projections of the same Core result |
| map marker/hover before hydration | Incomplete projection can leak as `UNKNOWN` | Gate projection on canonical actor + normalized presence |

The planned APIs should be thin public registration/facade seams. Do not make
the first migration a broad file split; isolate ownership and add contract
tests before moving internal code.

## Persistence and migration

Core persists source, group, actor, and provenance state. Hoomans persists its
PNC/body/provider projection. Expansion-owned state remains namespaced under
the expansion and must survive expansion disablement as opaque Core-linked
data where appropriate.

All adoption and migration is versioned, idempotent, additive, and bounded.
Existing canonical Core records must never be overwritten by a stale adopter
projection. Unknown or inactive expansion payloads must not be converted into
new actors merely because a marker or name exists.

## Forbidden designs

- Dynamic Trading or a Gang mod calling a private Hoomans generator directly.
- Project Hoomans creating a second actor when a source changes from abstract
  to live.
- Core containing trader/gang behavior or importing adopter modules.
- Map hover inferring state from a provider label or marker color.
- A compatibility fallback that silently becomes a second writer after the
  Core contract is active.
